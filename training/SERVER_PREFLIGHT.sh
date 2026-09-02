#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace/DubLabSRB"
PACKAGE="$ROOT/Server_Package"
REPO="$ROOT/index-tts-2-train"

echo
echo "========================================"
echo "DubLab SRB - SERVER PREFLIGHT V2"
echo "========================================"
echo

echo "=== 1. SYSTEM TOOLS ==="

for cmd in \
    bash \
    nvidia-smi \
    ffmpeg \
    sha256sum \
    unzip \
    uv
do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: required command not found: $cmd"
        exit 1
    fi

    echo "OK: $cmd"
done

echo
echo "=== 2. GPU ==="
nvidia-smi

echo
echo "=== 3. WORKSPACE ==="
df -h /workspace

FREE_GB=$(df -BG --output=avail /workspace | tail -1 | tr -dc '0-9')

echo "Free workspace: ${FREE_GB} GB"

if [ "$FREE_GB" -lt 180 ]; then
    echo "WARNING: less than 180 GB free."
    echo "For full ParlaSpeech preparation we prefer ~200-250+ GB."
fi

echo
echo "=== 4. PACKAGE FILES ==="

required=(
    "bpe_serbian_13005.model"
    "config_serbian_13005.yaml"
    "gpt_serbian_13005_init.pth"
    "index-tts-2-train.zip"
    "parlaspeech_sr_split_plan_v3.jsonl"
    "parlaspeech_sr_train_source.jsonl"
    "RUNPOD_SETUP.sh"
    "PREPARE_PARLASPEECH.sh"
    "BUILD_DATASET.py"
    "RUN_PREPROCESS.sh"
    "GENERATE_GPT_PAIRS.sh"
    "SMOKE_TEST.sh"
    "BENCHMARK_A40.sh"
    "TRAIN_FULL.sh"
    "SERVER_PREFLIGHT.sh"
    "RUNPOD_RUNBOOK.md"
    "SHA256SUMS.txt"
)

for f in "${required[@]}"; do

    if [ ! -f "$PACKAGE/$f" ]; then
        echo "ERROR: missing package file: $f"
        exit 1
    fi

    echo "OK: $f"
done

echo
echo "=== 5. SHA256 ==="

cd "$PACKAGE"
sha256sum -c SHA256SUMS.txt

echo
echo "=== 6. BASH SYNTAX ==="

for f in "$PACKAGE"/*.sh; do
    bash -n "$f"
    echo "OK: $(basename "$f")"
done

echo
echo "=== 7. TRAINER INSTALLATION ==="

if [ ! -d "$REPO" ]; then
    echo "ERROR: trainer is not installed."
    echo "Run RUNPOD_SETUP.sh first."
    exit 1
fi

trainer_required=(
    "pyproject.toml"
    "uv.lock"
    ".python-version"
    "tools/preprocess_data.py"
    "tools/generate_gpt_pairs.py"
    "tools/build_gpt_prompt_pairs.py"
    "trainers/train_gpt_v2.py"
    "indextts/gpt/model_v2.py"
)

for f in "${trainer_required[@]}"; do

    if [ ! -f "$REPO/$f" ]; then
        echo "ERROR: trainer file missing: $f"
        exit 1
    fi

    echo "OK: $f"
done

echo
echo "=== 8. SERBIAN CHECKPOINT COPIES ==="

serbian_checkpoint_files=(
    "bpe_serbian_13005.model"
    "config_serbian_13005.yaml"
    "gpt_serbian_13005_init.pth"
)

for f in "${serbian_checkpoint_files[@]}"; do
    src="$PACKAGE/$f"
    dst="$REPO/checkpoints/$f"

    if [ ! -f "$dst" ]; then
        echo "ERROR: Serbian checkpoint copy missing: $dst"
        exit 1
    fi

    src_sha="$(sha256sum "$src" | awk '{print $1}')"
    dst_sha="$(sha256sum "$dst" | awk '{print $1}')"

    if [ "$src_sha" != "$dst_sha" ]; then
        echo "ERROR: Serbian checkpoint copy differs: $f"
        echo "Package: $src_sha"
        echo "Trainer: $dst_sha"
        exit 1
    fi

    echo "OK: $f"
done

echo "SERBIAN CHECKPOINT COPIES: OK"

cd "$REPO"

echo
echo "=== 9. PYTHON / CUDA RUNTIME ==="

uv run python - <<'PY'
import sys
import torch

print("Python:", sys.version.split()[0])
print("PyTorch:", torch.__version__)
print("Torch CUDA build:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())

assert sys.version_info[:2] == (3, 11), (
    f"Expected Python 3.11, got {sys.version}"
)

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is not available")

print("CUDA device:", torch.cuda.get_device_name(0))
print("RUNTIME: OK")
PY

echo
echo "=== 10. PREPROCESS IMPORTS ==="

uv run python - <<'PY'
import librosa
import soundfile
import safetensors
import sentencepiece
import torchaudio
import transformers
import huggingface_hub

from omegaconf import OmegaConf

from transformers import (
    SeamlessM4TFeatureExtractor,
    Wav2Vec2BertModel,
)

from indextts.utils.maskgct_utils import (
    build_semantic_model,
    build_semantic_codec,
)

print("librosa: OK")
print("soundfile: OK")
print("safetensors: OK")
print("sentencepiece: OK")
print("torchaudio: OK")
print("transformers: OK")
print("huggingface_hub: OK")
print("omegaconf: OK")
print("SeamlessM4TFeatureExtractor: OK")
print("Wav2Vec2BertModel: OK")
print("MaskGCT imports: OK")
PY

echo
echo "=== 11. CLI TESTS ==="

uv run python tools/preprocess_data.py --help >/dev/null
echo "OK: preprocess_data.py"

uv run python tools/generate_gpt_pairs.py --help >/dev/null
echo "OK: generate_gpt_pairs.py"

uv run python trainers/train_gpt_v2.py --help >/dev/null
echo "OK: train_gpt_v2.py"

echo
echo "=== 12. BUILD_DATASET SYNTAX ==="

uv run python -m py_compile "$PACKAGE/BUILD_DATASET.py"

echo "OK: BUILD_DATASET.py"

echo
echo "=== 13. TRAINER-NATIVE SERBIAN MODEL LOAD ==="

uv run python - <<'PY'
import torch
from pathlib import Path
from omegaconf import OmegaConf

from trainers.train_gpt_v2 import (
    load_tokenizer,
    build_model,
)

root = Path("/workspace/DubLabSRB/Server_Package")

bpe = root / "bpe_serbian_13005.model"
cfg_path = root / "config_serbian_13005.yaml"
gpt_path = root / "gpt_serbian_13005_init.pth"

tokenizer = load_tokenizer(bpe)
cfg = OmegaConf.load(cfg_path)

print("Tokenizer vocab:", tokenizer.vocab_size)
print("Config vocab:", cfg.gpt.number_text_tokens)

assert tokenizer.vocab_size == 13005
assert cfg.gpt.number_text_tokens == 13005

model = build_model(
    cfg_path,
    tokenizer,
    gpt_path,
    torch.device("cpu"),
)

embedding = tuple(model.text_embedding.weight.shape)
head = tuple(model.text_head.weight.shape)
bias = tuple(model.text_head.bias.shape)

print("Embedding:", embedding)
print("Head:", head)
print("Bias:", bias)

assert embedding == (13006, 1280)
assert head == (13006, 1280)
assert bias == (13006,)

print("TRAINER-NATIVE SERBIAN GPT: OK")
PY

echo
echo "========================================"
echo "PREFLIGHT V2: SUCCESS"
echo "========================================"
echo
echo "Server environment is ready."
echo "Next stage: ParlaSpeech preparation."
