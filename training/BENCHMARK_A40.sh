#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace/DubLabSRB"
REPO="$ROOT/index-tts-2-train"
DATASET="$ROOT/processed/serbian"
TRAINING_ROOT="$ROOT/training"

TOKENIZER="$REPO/checkpoints/bpe_serbian_13005.model"
CONFIG="$REPO/checkpoints/config_serbian_13005.yaml"
GPT="$REPO/checkpoints/gpt_serbian_13005_init.pth"

TRAIN="$DATASET/gpt_pairs_train.jsonl"
VAL="$DATASET/gpt_pairs_val.jsonl"

# Первый запуск: 50 шагов.
# После успешного smoke-test:
# MAX_STEPS=500 bash BENCHMARK_A40.sh
MAX_STEPS="${MAX_STEPS:-50}"

if ! [[ "$MAX_STEPS" =~ ^[1-9][0-9]*$ ]]; then
    echo "ERROR: MAX_STEPS must be a positive integer."
    echo "Actual: $MAX_STEPS"
    exit 1
fi
OUT="$TRAINING_ROOT/a40_benchmark_${MAX_STEPS}"
RUN_NAME="serbian_a40_benchmark_${MAX_STEPS}"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/benchmark_a40_${MAX_STEPS}.log"
WARMUP_STEPS="${WARMUP_STEPS:-1000}"
LOG_INTERVAL="${LOG_INTERVAL:-10}"
VAL_INTERVAL="${VAL_INTERVAL:-1000}"

# Начинаем максимально безопасно для 48 GB VRAM.
BATCH_SIZE="${BATCH_SIZE:-1}"
GRAD_ACCUM="${GRAD_ACCUM:-4}"

CACHE="$ROOT/cache"

export HF_HOME="$CACHE/huggingface"
export HUGGINGFACE_HUB_CACHE="$CACHE/huggingface/hub"
export TORCH_HOME="$CACHE/torch"
export TMPDIR="$ROOT/tmp"
export PYTHONUNBUFFERED=1

mkdir -p "$CACHE/huggingface" "$CACHE/torch" "$TMPDIR" "$TRAINING_ROOT" "$LOG_DIR"

# Verify every benchmark input before deleting an old run.
for f in \
    "$TOKENIZER" \
    "$CONFIG" \
    "$GPT" \
    "$TRAIN" \
    "$VAL"
do
    if [ ! -s "$f" ]; then
        echo "ERROR: benchmark input missing or empty: $f"
        exit 1
    fi

    echo "OK: $f"
done

# Safety guard before deleting an old benchmark run.
case "$OUT" in
    "$TRAINING_ROOT"/a40_benchmark_[0-9]*)
        ;;
    *)
        echo "ERROR: refusing to clean unexpected benchmark path: $OUT"
        exit 1
        ;;
esac

echo "Cleaning benchmark output: $OUT"
rm -rf -- "$OUT"
mkdir -p "$OUT"

echo "========================================"
echo "DubLab SRB - A40 TRAINING BENCHMARK"
echo "========================================"

echo "Steps:             $MAX_STEPS"
echo "Batch size:        $BATCH_SIZE"
echo "Grad accumulation: $GRAD_ACCUM"
echo


echo "=== GPU BEFORE ==="
nvidia-smi

echo
echo "=== DISK BEFORE ==="
df -h /workspace

DISK_FREE_BEFORE_KB="$(df -Pk /workspace | awk 'NR==2 {print $4}')"

if ! [[ "$DISK_FREE_BEFORE_KB" =~ ^[0-9]+$ ]]; then
    echo "ERROR: unable to read free disk space before benchmark."
    echo "Actual: $DISK_FREE_BEFORE_KB"
    exit 1
fi

echo "Free before KiB: $DISK_FREE_BEFORE_KB"

cd "$REPO"

rm -f "$LOG_FILE"
echo "Benchmark log: $LOG_FILE"

echo
echo "=== PEAK VRAM MONITOR ==="

GPU_INDEX="${GPU_INDEX:-0}"
VRAM_LOG="$OUT/vram_samples_mib.txt"
VRAM_ERROR="$OUT/vram_monitor_error.txt"

if ! [[ "$GPU_INDEX" =~ ^[0-9]+$ ]]; then
    echo "ERROR: GPU_INDEX must be a non-negative integer."
    echo "Actual: $GPU_INDEX"
    exit 1
fi

VRAM_BASELINE_MIB="$(
    nvidia-smi -i "$GPU_INDEX" \
        --query-gpu=memory.used \
        --format=csv,noheader,nounits \
        | tr -d "[:space:]"
)"

if ! [[ "$VRAM_BASELINE_MIB" =~ ^[0-9]+$ ]]; then
    echo "ERROR: unable to read baseline GPU memory usage."
    echo "Actual: $VRAM_BASELINE_MIB"
    exit 1
fi

: > "$VRAM_LOG"
rm -f "$VRAM_ERROR"

VRAM_MONITOR_PID=""

stop_vram_monitor() {
    if [ -n "${VRAM_MONITOR_PID:-}" ]; then
        if kill -0 "$VRAM_MONITOR_PID" 2>/dev/null; then
            kill "$VRAM_MONITOR_PID" 2>/dev/null || true
        fi

        wait "$VRAM_MONITOR_PID" 2>/dev/null || true
        VRAM_MONITOR_PID=""
    fi
}

trap stop_vram_monitor EXIT

(
    while true; do
        value="$(
            nvidia-smi -i "$GPU_INDEX" \
                --query-gpu=memory.used \
                --format=csv,noheader,nounits \
                2>/dev/null \
                | tr -d "[:space:]"
        )" || {
            echo "nvidia-smi query failed" > "$VRAM_ERROR"
            exit 1
        }

        case "$value" in
            ""|*[!0-9]*)
                echo "Invalid VRAM sample: $value" > "$VRAM_ERROR"
                exit 1
                ;;
        esac

        printf "%s\n" "$value" >> "$VRAM_LOG"
        sleep 0.5
    done
) &

VRAM_MONITOR_PID=$!

echo "GPU index:          $GPU_INDEX"
echo "VRAM baseline MiB:  $VRAM_BASELINE_MIB"
echo "VRAM sampler PID:   $VRAM_MONITOR_PID"

START_TIME=$(date +%s)

echo
echo "=== TRAINING START ==="

INDEXTTS_RUN_NAME="$RUN_NAME" \
uv run python trainers/train_gpt_v2.py \
    --train-manifest "$TRAIN::sr" \
    --val-manifest "$VAL::sr" \
    --tokenizer "$TOKENIZER" \
    --config "$CONFIG" \
    --base-checkpoint "$GPT" \
    --output-dir "$OUT" \
    --batch-size "$BATCH_SIZE" \
    --grad-accumulation "$GRAD_ACCUM" \
    --epochs 999 \
    --learning-rate 2e-5 \
    --weight-decay 0.01 \
    --warmup-steps "$WARMUP_STEPS" \
    --max-steps "$MAX_STEPS" \
    --log-interval "$LOG_INTERVAL" \
    --val-interval "$VAL_INTERVAL" \
    --num-workers 0 \
    --grad-clip 1.0 \
    --text-loss-weight 0.2 \
    --mel-loss-weight 0.8 \
    --amp 2>&1 | tee "$LOG_FILE"

END_TIME=$(date +%s)

stop_vram_monitor
trap - EXIT

if [ -s "$VRAM_ERROR" ]; then
    echo "ERROR: VRAM monitor failed:"
    cat "$VRAM_ERROR"
    exit 1
fi

if [ ! -s "$VRAM_LOG" ]; then
    echo "ERROR: VRAM monitor produced no samples."
    exit 1
fi

VRAM_SAMPLE_COUNT=$(awk 'END { print NR }' "$VRAM_LOG")

PEAK_VRAM_MIB=$(awk '
    BEGIN { max = -1 }
    /^[0-9]+$/ {
        if ($1 > max) max = $1
    }
    END {
        if (max < 0) exit 1
        print max
    }
' "$VRAM_LOG")

if ! [[ "$PEAK_VRAM_MIB" =~ ^[0-9]+$ ]]; then
    echo "ERROR: invalid peak VRAM result: $PEAK_VRAM_MIB"
    exit 1
fi

VRAM_DELTA_MIB=$((PEAK_VRAM_MIB - VRAM_BASELINE_MIB))

if [ "$VRAM_DELTA_MIB" -lt 0 ]; then
    VRAM_DELTA_MIB=0
fi

echo
echo "=== VRAM RESULT ==="
echo "VRAM samples:       $VRAM_SAMPLE_COUNT"
echo "VRAM baseline MiB:  $VRAM_BASELINE_MIB"
echo "VRAM peak MiB:      $PEAK_VRAM_MIB"
echo "VRAM delta MiB:     $VRAM_DELTA_MIB"

ELAPSED=$((END_TIME - START_TIME))

echo
echo "=== CHECKPOINT VALIDATION ==="

STEP_CKPT="$OUT/model_step${MAX_STEPS}.pth"
LATEST_CKPT="$OUT/latest.pth"

for f in "$STEP_CKPT" "$LATEST_CKPT"; do
    if [ ! -s "$f" ]; then
        echo "ERROR: benchmark checkpoint missing or empty: $f"
        exit 1
    fi
done

uv run python - "$STEP_CKPT" "$LATEST_CKPT" "$MAX_STEPS" <<'PY'
import sys
from pathlib import Path
import torch

expected_step = int(sys.argv[3])

for value in sys.argv[1:3]:
    path = Path(value)
    checkpoint = torch.load(
        path,
        map_location="cpu",
        weights_only=False,
    )

    step = int(checkpoint.get("step", -1))
    print(f"{path.name} step: {step}")

    if step != expected_step:
        raise RuntimeError(
            f"{path.name}: expected step {expected_step}, got {step}"
        )

print("CHECKPOINT CONTENT: OK")
PY

echo "BENCHMARK CHECKPOINTS: OK"

echo
echo "========================================"
echo "BENCHMARK TRAINING RESULT"
echo "========================================"

echo "Optimizer steps: $MAX_STEPS"
echo "Wall time:       $ELAPSED sec"

python3 - <<PY
steps = $MAX_STEPS
seconds = $ELAPSED

print("Average including startup:",
      round(seconds / steps, 3),
      "sec/optimizer-step")
PY

echo
echo "=== CHECKPOINTS ==="
ls -lh "$OUT"

echo
echo "=== GPU AFTER ==="
nvidia-smi

echo
echo "=== DISK AFTER ==="
df -h /workspace

DISK_FREE_AFTER_KB="$(df -Pk /workspace | awk 'NR==2 {print $4}')"
OUT_SIZE_KB="$(du -sk "$OUT" | awk '{print $1}')"

if ! [[ "$DISK_FREE_AFTER_KB" =~ ^[0-9]+$ ]]; then
    echo "ERROR: unable to read free disk space after benchmark."
    exit 1
fi

if ! [[ "$OUT_SIZE_KB" =~ ^[0-9]+$ ]]; then
    echo "ERROR: unable to calculate benchmark output size."
    exit 1
fi

DISK_USED_DELTA_KB=$((DISK_FREE_BEFORE_KB - DISK_FREE_AFTER_KB))

if [ "$DISK_USED_DELTA_KB" -lt 0 ]; then
    DISK_USED_DELTA_KB=0
fi
du -sh "$OUT"


STEP_CKPT_SIZE_BYTES="$(stat -c %s "$STEP_CKPT")"
LATEST_CKPT_SIZE_BYTES="$(stat -c %s "$LATEST_CKPT")"

SUMMARY_FILE="$OUT/benchmark_summary.txt"

uv run python - \
    "$MAX_STEPS" \
    "$ELAPSED" \
    "$VRAM_BASELINE_MIB" \
    "$PEAK_VRAM_MIB" \
    "$VRAM_DELTA_MIB" \
    "$VRAM_SAMPLE_COUNT" \
    "$DISK_FREE_BEFORE_KB" \
    "$DISK_FREE_AFTER_KB" \
    "$DISK_USED_DELTA_KB" \
    "$OUT_SIZE_KB" \
    "$STEP_CKPT_SIZE_BYTES" \
    "$LATEST_CKPT_SIZE_BYTES" \
    "$OUT" \
    "$LOG_FILE" \
    "$SUMMARY_FILE" <<'PY'
import sys
from pathlib import Path

(
    steps,
    elapsed,
    baseline,
    peak,
    delta,
    samples,
    free_before,
    free_after,
    disk_delta,
    out_size,
    step_ckpt_size,
    latest_ckpt_size,
    out_dir,
    log_file,
    summary_file,
) = sys.argv[1:]

steps = int(steps)
elapsed = int(elapsed)
baseline = int(baseline)
peak = int(peak)
delta = int(delta)
samples = int(samples)
free_before = int(free_before)
free_after = int(free_after)
disk_delta = int(disk_delta)
out_size = int(out_size)
step_ckpt_size = int(step_ckpt_size)
latest_ckpt_size = int(latest_ckpt_size)

sec_per_step = elapsed / steps

def gib_from_kib(value):
    return value / 1024 / 1024

def gib_from_bytes(value):
    return value / 1024 / 1024 / 1024

report = f"""BENCHMARK SUMMARY
=================
Optimizer steps:             {steps}
Wall time:                   {elapsed} sec
Average incl. startup:       {sec_per_step:.3f} sec/optimizer-step

VRAM baseline:               {baseline} MiB
VRAM peak:                   {peak} MiB
VRAM delta:                  {delta} MiB
VRAM samples:                {samples}

Free disk before:            {gib_from_kib(free_before):.3f} GiB
Free disk after:             {gib_from_kib(free_after):.3f} GiB
Disk delta during benchmark: {gib_from_kib(disk_delta):.3f} GiB
Benchmark output size:       {gib_from_kib(out_size):.3f} GiB

model_step checkpoint:       {gib_from_bytes(step_ckpt_size):.3f} GiB
latest checkpoint:           {gib_from_bytes(latest_ckpt_size):.3f} GiB

Output directory:            {out_dir}
Trainer log:                 {log_file}
"""

print(report)
Path(summary_file).write_text(report + "\n", encoding="utf-8")
PY

if [ ! -s "$SUMMARY_FILE" ]; then
    echo "ERROR: benchmark summary was not created."
    exit 1
fi

echo
echo "Summary: $SUMMARY_FILE"
echo
echo "========================================"
echo "BENCHMARK SUCCESS"
echo "========================================"
