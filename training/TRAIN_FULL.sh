#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace/DubLabSRB"
REPO="$ROOT/index-tts-2-train"
DATASET="$ROOT/processed/serbian"
OUT="$ROOT/training/serbian_full"

TOKENIZER="$REPO/checkpoints/bpe_serbian_13005.model"
CONFIG="$REPO/checkpoints/config_serbian_13005.yaml"
GPT="$REPO/checkpoints/gpt_serbian_13005_init.pth"

TRAIN="$DATASET/gpt_pairs_train.jsonl"
VAL="$DATASET/gpt_pairs_val.jsonl"

BATCH_SIZE="${BATCH_SIZE:-1}"
GRAD_ACCUM="${GRAD_ACCUM:-4}"
EPOCHS="${EPOCHS:-2}"
LR="${LR:-2e-5}"
MIN_FREE_GB="${MIN_FREE_GB:-40}"


CACHE="$ROOT/cache"

export HF_HOME="$CACHE/huggingface"
export HUGGINGFACE_HUB_CACHE="$CACHE/huggingface/hub"
export TORCH_HOME="$CACHE/torch"
export TMPDIR="$ROOT/tmp"
export PYTHONUNBUFFERED=1

mkdir -p \
    "$OUT" \
    "$ROOT/logs" \
    "$CACHE/huggingface" \
    "$CACHE/torch" \
    "$TMPDIR"

echo "========================================"
echo "DubLab SRB - FULL TRAINING"
echo "========================================"

echo "Batch size:        $BATCH_SIZE"
echo "Grad accumulation: $GRAD_ACCUM"
echo "Epochs:            $EPOCHS"
echo "Learning rate:     $LR"
echo

echo "=== INPUT CHECK ==="

for f in \
    "$TOKENIZER" \
    "$CONFIG" \
    "$GPT" \
    "$TRAIN" \
    "$VAL"
do
    if [ ! -s "$f" ]; then
        echo "ERROR: training input missing or empty: $f"
        return 1 2>/dev/null || exit 1
    fi

    echo "OK: $f"
done

echo "=== GPU ==="
nvidia-smi

echo
echo "=== DISK ==="
df -h /workspace

FREE_GB=$(df -BG --output=avail /workspace | tail -1 | tr -dc '0-9')

if ! [[ "$MIN_FREE_GB" =~ ^[0-9]+$ ]]; then
    echo "ERROR: MIN_FREE_GB must be a non-negative integer."
    echo "Actual: $MIN_FREE_GB"
    return 1 2>/dev/null || exit 1
fi

if [ "$FREE_GB" -lt "$MIN_FREE_GB" ]; then
    echo "ERROR: less than $MIN_FREE_GB GiB free for training/checkpoints."
    exit 1
fi

cd "$REPO"

echo
echo "=== RESUME CHECK ==="

RESUME_ARGS=()
RESUME_CANDIDATES=0

if [ -e "$OUT/latest.pth" ]; then
    RESUME_CANDIDATES=$((RESUME_CANDIDATES + 1))
fi

shopt -s nullglob
MODEL_STEP_CANDIDATES=("$OUT"/model_step*.pth)
shopt -u nullglob

RESUME_CANDIDATES=$((RESUME_CANDIDATES + ${#MODEL_STEP_CANDIDATES[@]}))

if [ "$RESUME_CANDIDATES" -gt 0 ]; then
    echo "Checkpoint candidates found: $RESUME_CANDIDATES"
    echo "Trainer will validate and select the safest resume checkpoint."
    RESUME_ARGS=(--resume auto)
else
    # Starting fresh inside a non-empty training directory is unsafe.
    shopt -s nullglob dotglob
    OUT_CONTENTS=("$OUT"/*)
    shopt -u nullglob dotglob

    if [ "${#OUT_CONTENTS[@]}" -gt 0 ]; then
        echo "ERROR: training output directory is not empty, but no resume checkpoint exists."
        echo "Directory: $OUT"
        echo "Refusing to start fresh over unknown training artifacts."
        return 1 2>/dev/null || exit 1
    fi

    echo "No checkpoint candidates found. Starting fresh."
fi

echo "=== TRAINING START ==="

INDEXTTS_RUN_NAME="serbian_full" \
uv run python trainers/train_gpt_v2.py \
    --train-manifest "$TRAIN::sr" \
    --val-manifest "$VAL::sr" \
    --tokenizer "$TOKENIZER" \
    --config "$CONFIG" \
    --base-checkpoint "$GPT" \
    --output-dir "$OUT" \
    --batch-size "$BATCH_SIZE" \
    --grad-accumulation "$GRAD_ACCUM" \
    --epochs "$EPOCHS" \
    --learning-rate "$LR" \
    --weight-decay 0.01 \
    --warmup-steps 1000 \
    --log-interval 10 \
    --val-interval 1000 \
    --num-workers 0 \
    --grad-clip 1.0 \
    --text-loss-weight 0.2 \
    --mel-loss-weight 0.8 \
    --min-free-disk-gb "$MIN_FREE_GB" \
    --amp \
    "${RESUME_ARGS[@]}" \
    2>&1 | tee -a "$ROOT/logs/train_full.log"

echo
echo "=== FINAL CHECKPOINT VALIDATION ==="

FINAL_LATEST="$OUT/latest.pth"

if [ ! -s "$FINAL_LATEST" ]; then
    echo "ERROR: final latest.pth is missing or empty: $FINAL_LATEST"
    return 1 2>/dev/null || exit 1
fi

uv run python - "$FINAL_LATEST" "$TRAIN" "$VAL" "$OUT" "$EPOCHS" sr <<'PY'
from pathlib import Path
import hashlib
import sys
import torch


latest_path = Path(sys.argv[1]).resolve()
train_path = Path(sys.argv[2]).resolve()
val_path = Path(sys.argv[3]).resolve()
output_dir = Path(sys.argv[4]).resolve()
expected_epochs = int(sys.argv[5])
expected_language = sys.argv[6]


def fail(message: str) -> None:
    raise RuntimeError(message)


def fingerprint(path: Path) -> tuple[int, str, int]:
    if not path.is_file():
        fail(f"Manifest missing during final validation: {path}")

    digest = hashlib.sha256()
    count = 0

    with path.open("rb") as handle:
        while True:
            chunk = handle.read(1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)

    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if line.strip():
                count += 1

    return path.stat().st_size, digest.hexdigest(), count


def validate_manifest(
    manifests: dict,
    role: str,
    expected_path: Path,
) -> None:
    entries = manifests.get(role)

    if not isinstance(entries, list) or len(entries) != 1:
        fail(
            f"Checkpoint manifest role {role!r} must contain exactly one entry."
        )

    entry = entries[0]

    if not isinstance(entry, dict):
        fail(f"Checkpoint manifest entry {role!r} is not a dictionary.")

    required = {
        "path",
        "count",
        "languages",
        "bytes",
        "sha256",
    }

    missing = sorted(required - set(entry))
    if missing:
        fail(
            f"Checkpoint manifest entry {role!r} is missing: "
            + ", ".join(missing)
        )

    stored_path = Path(entry["path"]).resolve()

    if stored_path != expected_path:
        fail(
            f"{role} manifest path mismatch: "
            f"checkpoint={stored_path}, current={expected_path}"
        )

    current_bytes, current_sha256, current_count = fingerprint(expected_path)

    if int(entry["bytes"]) != current_bytes:
        fail(
            f"{role} manifest byte-size mismatch: "
            f"checkpoint={entry['bytes']}, current={current_bytes}"
        )

    if str(entry["sha256"]) != current_sha256:
        fail(f"{role} manifest SHA256 mismatch.")

    if int(entry["count"]) != current_count:
        fail(
            f"{role} manifest record-count mismatch: "
            f"checkpoint={entry['count']}, current={current_count}"
        )

    languages = entry["languages"]
    if not isinstance(languages, list):
        fail(f"{role} manifest languages is not a list.")

    if languages != [expected_language]:
        fail(
            f"{role} manifest language mismatch: "
            f"checkpoint={languages}, expected={[expected_language]}"
        )

    print(
        f"{role}: count={current_count}, "
        f"bytes={current_bytes}, sha256={current_sha256}"
    )


print("Loading:", latest_path)

checkpoint = torch.load(
    latest_path,
    map_location="cpu",
    weights_only=False,
)

if not isinstance(checkpoint, dict):
    fail("latest.pth root is not a dictionary.")

required_keys = {
    "model",
    "optimizer",
    "scheduler",
    "scaler",
    "epoch",
    "step",
    "recent_checkpoints",
    "manifests",
}

missing_keys = sorted(required_keys - set(checkpoint))

if missing_keys:
    fail(
        "latest.pth missing required keys: "
        + ", ".join(missing_keys)
    )

if checkpoint["model"] is None:
    fail("latest.pth model state is missing.")

if checkpoint["optimizer"] is None:
    fail("latest.pth optimizer state is missing.")

if checkpoint["scheduler"] is None:
    fail("latest.pth scheduler state is missing.")

try:
    epoch = int(checkpoint["epoch"])
    step = int(checkpoint["step"])
except (TypeError, ValueError) as exc:
    fail(f"Invalid epoch/step metadata: {exc}")

if epoch < expected_epochs:
    fail(
        f"Training target not reached: "
        f"checkpoint epoch={epoch}, expected at least {expected_epochs}."
    )

if step <= 0:
    fail(f"Invalid final optimizer step: {step}")

recent = checkpoint["recent_checkpoints"]

if not isinstance(recent, list) or not recent:
    fail("latest.pth has no retained model_step checkpoint reference.")

final_model_step = (output_dir / f"model_step{step}.pth").resolve()

if not final_model_step.is_file():
    fail(f"Final model_step checkpoint is missing: {final_model_step}")

if final_model_step.stat().st_size <= 0:
    fail(f"Final model_step checkpoint is empty: {final_model_step}")

recent_paths = [Path(value).resolve() for value in recent]

if final_model_step not in recent_paths:
    fail(
        f"latest.pth does not reference its final model_step checkpoint: "
        f"{final_model_step}"
    )


print("Loading fallback:", final_model_step)

model_step_checkpoint = torch.load(
    final_model_step,
    map_location="cpu",
    weights_only=False,
)

if not isinstance(model_step_checkpoint, dict):
    fail("Final model_step checkpoint root is not a dictionary.")

required_model_step_keys = {
    "model",
    "optimizer",
    "scheduler",
    "scaler",
    "epoch",
    "step",
    "recent_checkpoints",
    "extra",
}

missing_model_step_keys = sorted(
    required_model_step_keys - set(model_step_checkpoint)
)

if missing_model_step_keys:
    fail(
        "Final model_step checkpoint missing required keys: "
        + ", ".join(missing_model_step_keys)
    )

if model_step_checkpoint["model"] is None:
    fail("Final model_step model state is missing.")

if model_step_checkpoint["optimizer"] is None:
    fail("Final model_step optimizer state is missing.")

if model_step_checkpoint["scheduler"] is None:
    fail("Final model_step scheduler state is missing.")

try:
    model_step_epoch = int(model_step_checkpoint["epoch"])
    model_step_step = int(model_step_checkpoint["step"])
except (TypeError, ValueError) as exc:
    fail(f"Final model_step has invalid epoch/step metadata: {exc}")

if model_step_step != step:
    fail(
        f"Final model_step step mismatch: "
        f"model_step={model_step_step}, latest={step}"
    )

if model_step_epoch != epoch:
    fail(
        f"Final model_step epoch mismatch: "
        f"model_step={model_step_epoch}, latest={epoch}"
    )

model_step_recent = model_step_checkpoint["recent_checkpoints"]

if not isinstance(model_step_recent, list):
    fail("Final model_step recent_checkpoints is not a list.")

model_step_extra = model_step_checkpoint["extra"]

if not isinstance(model_step_extra, dict):
    fail("Final model_step extra metadata is not a dictionary.")

if model_step_extra.get("type") != "step-final":
    fail(
        f"Final model_step type mismatch: "
        f"{model_step_extra.get('type')!r}"
    )

model_step_manifests = model_step_extra.get("manifests")

if model_step_manifests is None:
    fail("Final model_step has no manifest identity metadata.")

if model_step_manifests != checkpoint["manifests"]:
    fail(
        "Final model_step manifest identity differs from latest.pth."
    )

print("FINAL MODEL_STEP CONTENT: OK")

manifests = checkpoint["manifests"]

if not isinstance(manifests, dict):
    fail("latest.pth manifests metadata is not a dictionary.")

validate_manifest(manifests, "train", train_path)
validate_manifest(manifests, "val", val_path)

print(f"Checkpoint epoch: {epoch}")
print(f"Checkpoint step:  {step}")
print(f"model_step:       {final_model_step}")
print("FINAL CHECKPOINT CONTENT: OK")
PY

echo "FINAL CHECKPOINT VALIDATION: OK"


echo
echo "========================================"
echo "TRAINING COMPLETE"
echo "========================================"

ls -lh "$OUT"
df -h /workspace
