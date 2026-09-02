#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace/DubLabSRB"
REPO="$ROOT/index-tts-2-train"
DATASET="$ROOT/processed/serbian"

# 0 = без ограничения.
# Для теста можно:
# MAX_PAIRS=1000 bash GENERATE_GPT_PAIRS.sh
MAX_PAIRS="${MAX_PAIRS:-0}"

echo "========================================"
echo "DubLab SRB - GPT prompt/target pairs"
echo "========================================"

for file in \
    "$DATASET/train_manifest.jsonl" \
    "$DATASET/val_manifest.jsonl"
do
    if [ ! -f "$file" ]; then
        echo "ERROR: missing $file"
        exit 1
    fi
done

cd "$REPO"

uv run python tools/generate_gpt_pairs.py \
    --dataset "$DATASET" \
    --pairs-per-target 2 \
    --max-pairs "$MAX_PAIRS" \
    --min-text-len 1 \
    --min-code-len 1 \
    --seed 2025 \
    --force

echo
echo "========================================"
echo "GPT PAIRS READY"
echo "========================================"

echo -n "Train utterances: "
wc -l < "$DATASET/train_manifest.jsonl"

echo -n "Val utterances:   "
wc -l < "$DATASET/val_manifest.jsonl"

echo -n "Train pairs:      "
wc -l < "$DATASET/gpt_pairs_train.jsonl"

echo -n "Val pairs:        "
wc -l < "$DATASET/gpt_pairs_val.jsonl"

echo
echo "First training pair:"
head -n 1 "$DATASET/gpt_pairs_train.jsonl"