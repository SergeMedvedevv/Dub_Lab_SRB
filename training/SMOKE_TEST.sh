#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace/DubLabSRB"
REPO="$ROOT/index-tts-2-train"

READY="$ROOT/manifests/parlaspeech_sr_ready.jsonl"
SMOKE="$ROOT/processed/smoke"
TRAIN_OUT="$ROOT/training/smoke_test"

TOKENIZER="$REPO/checkpoints/bpe_serbian_13005.model"
CONFIG="$REPO/checkpoints/config_serbian_13005.yaml"
GPT="$REPO/checkpoints/gpt_serbian_13005_init.pth"

CACHE="$ROOT/cache"

export HF_HOME="$CACHE/huggingface"
export HUGGINGFACE_HUB_CACHE="$CACHE/huggingface/hub"
export TORCH_HOME="$CACHE/torch"
export TMPDIR="$ROOT/tmp"
export PYTHONUNBUFFERED=1

mkdir -p "$CACHE/huggingface" "$CACHE/torch" "$TMPDIR"

echo "========================================"
echo "DubLab SRB - END-TO-END SMOKE TEST"
echo "========================================"

if [ ! -f "$READY" ]; then
    echo "ERROR: dataset manifest not ready:"
    echo "$READY"
    echo "Run PREPARE_PARLASPEECH.sh and BUILD_DATASET.py first."
    exit 1
fi

READY_COUNT=$(wc -l < "$READY")
echo "Ready manifest samples: $READY_COUNT"

if [ "$READY_COUNT" -ne 304450 ]; then
    echo "ERROR: unexpected ready manifest size."
    echo "Expected: 304450"
    echo "Actual:   $READY_COUNT"
    exit 1
fi

echo "READY MANIFEST: OK"

rm -rf "$SMOKE" "$TRAIN_OUT"
mkdir -p "$SMOKE" "$TRAIN_OUT"

cd "$REPO"

echo
echo "=== 1/3 PREPROCESS 50 SAMPLES ==="

uv run python tools/preprocess_data.py \
    --manifest "$READY" \
    --output-dir "$SMOKE" \
    --tokenizer "$TOKENIZER" \
    --config "$CONFIG" \
    --gpt-checkpoint "$GPT" \
    --language sr \
    --device cuda \
    --val-ratio 0.10 \
    --seed 17 \
    --max-samples 50 \
    --batch-size 1 \
    --workers 0

echo
echo
echo "=== PREPROCESS ARTIFACT CHECK ==="

PRE_TRAIN="$SMOKE/train_manifest.jsonl"
PRE_VAL="$SMOKE/val_manifest.jsonl"
PRE_STATS="$SMOKE/stats.json"

for f in "$PRE_TRAIN" "$PRE_VAL" "$PRE_STATS"; do
    if [ ! -s "$f" ]; then
        echo "ERROR: preprocess artifact missing or empty: $f"
        exit 1
    fi
done

PRE_TRAIN_COUNT=$(wc -l < "$PRE_TRAIN")
PRE_VAL_COUNT=$(wc -l < "$PRE_VAL")
PRE_TOTAL=$((PRE_TRAIN_COUNT + PRE_VAL_COUNT))

echo "Preprocess train samples: $PRE_TRAIN_COUNT"
echo "Preprocess val samples:   $PRE_VAL_COUNT"
echo "Preprocess total:         $PRE_TOTAL"

if [ "$PRE_TOTAL" -ne 50 ]; then
    echo "ERROR: expected exactly 50 preprocessed smoke samples."
    echo "Actual: $PRE_TOTAL"
    exit 1
fi

if [ "$PRE_TRAIN_COUNT" -eq 0 ] || [ "$PRE_VAL_COUNT" -eq 0 ]; then
    echo "ERROR: smoke train/val split contains an empty side."
    exit 1
fi

echo "PREPROCESS ARTIFACTS: OK"

echo "=== 2/3 BUILD GPT PAIRS ==="

uv run python tools/generate_gpt_pairs.py \
    --dataset "$SMOKE" \
    --pairs-per-target 2 \
    --max-pairs 100 \
    --min-text-len 1 \
    --min-code-len 1 \
    --seed 2025 \
    --force

echo
echo
echo "=== GPT PAIR ARTIFACT CHECK ==="

PAIR_TRAIN="$SMOKE/gpt_pairs_train.jsonl"
PAIR_VAL="$SMOKE/gpt_pairs_val.jsonl"

for f in "$PAIR_TRAIN" "$PAIR_VAL"; do
    if [ ! -s "$f" ]; then
        echo "ERROR: GPT pair manifest missing or empty: $f"
        exit 1
    fi
done

PAIR_TRAIN_COUNT=$(wc -l < "$PAIR_TRAIN")
PAIR_VAL_COUNT=$(wc -l < "$PAIR_VAL")

echo "GPT train pairs: $PAIR_TRAIN_COUNT"
echo "GPT val pairs:   $PAIR_VAL_COUNT"

if [ "$PAIR_TRAIN_COUNT" -lt 1 ] || [ "$PAIR_TRAIN_COUNT" -gt 100 ]; then
    echo "ERROR: unexpected number of GPT train pairs: $PAIR_TRAIN_COUNT"
    exit 1
fi

if [ "$PAIR_VAL_COUNT" -lt 1 ] || [ "$PAIR_VAL_COUNT" -gt 100 ]; then
    echo "ERROR: unexpected number of GPT val pairs: $PAIR_VAL_COUNT"
    exit 1
fi

echo "GPT PAIR ARTIFACTS: OK"

echo "=== 3/3 TRAIN 20 OPTIMIZER STEPS ==="

uv run python trainers/train_gpt_v2.py \
    --train-manifest "$SMOKE/gpt_pairs_train.jsonl::sr" \
    --val-manifest "$SMOKE/gpt_pairs_val.jsonl::sr" \
    --tokenizer "$TOKENIZER" \
    --config "$CONFIG" \
    --base-checkpoint "$GPT" \
    --output-dir "$TRAIN_OUT" \
    --batch-size 1 \
    --grad-accumulation 4 \
    --epochs 999 \
    --learning-rate 2e-5 \
    --weight-decay 0.01 \
    --warmup-steps 5 \
    --max-steps 20 \
    --log-interval 1 \
    --val-interval 0 \
    --num-workers 0 \
    --grad-clip 1.0 \
    --text-loss-weight 0.2 \
    --mel-loss-weight 0.8 \
    --amp

echo
echo "=== TRAINING CHECKPOINT CHECK ==="

STEP_CKPT="$TRAIN_OUT/model_step20.pth"
LATEST_CKPT="$TRAIN_OUT/latest.pth"

for f in "$STEP_CKPT" "$LATEST_CKPT"; do
    if [ ! -s "$f" ]; then
        echo "ERROR: training checkpoint missing or empty: $f"
        exit 1
    fi
done

uv run python - "$STEP_CKPT" "$LATEST_CKPT" <<'PY'
import sys
from pathlib import Path
import torch

for value in sys.argv[1:]:
    path = Path(value)
    checkpoint = torch.load(
        path,
        map_location="cpu",
        weights_only=False,
    )

    step = int(checkpoint.get("step", -1))
    print(f"{path.name} step: {step}")

    if step != 20:
        raise RuntimeError(
            f"{path.name}: expected step 20, got {step}"
        )

print("CHECKPOINT CONTENT: OK")
PY

echo "TRAINING CHECKPOINTS: OK"


echo

echo
echo "Smoke features:"
du -sh "$SMOKE"

echo
echo "Training output:"
ls -lh "$TRAIN_OUT"

echo
nvidia-smi
df -h /workspace

echo
echo "========================================"
echo "SMOKE TEST SUCCESS"
echo "========================================"
