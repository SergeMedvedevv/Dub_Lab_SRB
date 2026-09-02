#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace/DubLabSRB"
PACKAGE="$ROOT/Server_Package"
REPO="$ROOT/index-tts-2-train"

MANIFEST="$ROOT/manifests/parlaspeech_sr_ready.jsonl"
OUTPUT="$ROOT/processed/serbian"

TOKENIZER="$REPO/checkpoints/bpe_serbian_13005.model"
CONFIG="$REPO/checkpoints/config_serbian_13005.yaml"
GPT="$REPO/checkpoints/gpt_serbian_13005_init.pth"

CACHE="$ROOT/cache"

export HF_HOME="$CACHE/huggingface"
export HUGGINGFACE_HUB_CACHE="$CACHE/huggingface/hub"
export TORCH_HOME="$CACHE/torch"
export TMPDIR="$ROOT/tmp"
export PYTHONUNBUFFERED=1

# 0 = весь корпус.
# Для первого smoke-test можно запускать:
# MAX_SAMPLES=50 bash RUN_PREPROCESS.sh
MAX_SAMPLES="${MAX_SAMPLES:-0}"

mkdir -p "$OUTPUT" "$ROOT/logs" "$TMPDIR"

echo "========================================"
echo "DubLab SRB - preprocessing"
echo "========================================"
echo "Manifest:    $MANIFEST"
echo "Output:      $OUTPUT"
echo "Max samples: $MAX_SAMPLES"
echo

echo "=== GPU ==="
nvidia-smi

echo
echo "=== Disk before ==="
df -h /workspace

for file in \
    "$MANIFEST" \
    "$TOKENIZER" \
    "$CONFIG" \
    "$GPT"
do
    if [ ! -f "$file" ]; then
        echo "ERROR: missing $file"
        exit 1
    fi
done

cd "$REPO"

echo
echo "=== Starting preprocessing ==="

uv run python tools/preprocess_data.py \
    --manifest "$MANIFEST" \
    --output-dir "$OUTPUT" \
    --tokenizer "$TOKENIZER" \
    --config "$CONFIG" \
    --gpt-checkpoint "$GPT" \
    --language sr \
    --device cuda \
    --val-ratio 0.01 \
    --seed 17 \
    --max-samples "$MAX_SAMPLES" \
    --batch-size 1 \
    --workers 0 \
    --skip-existing \
    2>&1 | tee -a "$ROOT/logs/preprocess.log"

echo
echo "========================================"
echo "PREPROCESS COMPLETE"
echo "========================================"

cat "$OUTPUT/stats.json"

echo
echo "Feature files:"
echo -n "text_ids:  "
find "$OUTPUT/text_ids" -type f -name '*.npy' | wc -l
echo -n "codes:     "
find "$OUTPUT/codes" -type f -name '*.npy' | wc -l
echo -n "condition: "
find "$OUTPUT/condition" -type f -name '*.npy' | wc -l
echo -n "emo_vec:   "
find "$OUTPUT/emo_vec" -type f -name '*.npy' | wc -l

echo
echo "Disk after:"
du -sh "$OUTPUT"
df -h /workspace