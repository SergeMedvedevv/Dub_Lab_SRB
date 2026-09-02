#!/usr/bin/env bash
set -euo pipefail

ROOT="/workspace/DubLabSRB"
PACKAGE="$ROOT/Server_Package"
REPO="$ROOT/index-tts-2-train"
CACHE="$ROOT/cache"

echo "=== DubLab SRB / RunPod setup ==="

mkdir -p \
  "$ROOT" \
  "$CACHE/huggingface" \
  "$CACHE/torch" \
  "$CACHE/uv" \
  "$ROOT/tmp" \
  "$ROOT/processed" \
  "$ROOT/training"

export HF_HOME="$CACHE/huggingface"
export HUGGINGFACE_HUB_CACHE="$CACHE/huggingface/hub"
export TORCH_HOME="$CACHE/torch"
export UV_CACHE_DIR="$CACHE/uv"
export TMPDIR="$ROOT/tmp"

echo
echo "=== GPU ==="
nvidia-smi

echo
echo "=== Disk ==="
df -h /workspace

echo
echo "=== System packages ==="
apt-get update
apt-get install -y ffmpeg libsndfile1 unzip curl wget git git-lfs

echo
echo "=== Python / uv ==="
python3 -m pip install -U uv

echo "Installing Python 3.11 via uv..."
uv python install 3.11

echo
echo "=== Installing our frozen trainer build ==="

rm -rf "$REPO"
mkdir -p "$REPO"

unzip -q "$PACKAGE/index-tts-2-train.zip" -d "$REPO"

cd "$REPO"

uv sync --python 3.11

echo
echo "=== Verified runtime ==="

uv run python -V

uv run python - <<'PY'
import torch

print("PyTorch:", torch.__version__)
print("Torch CUDA build:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())

if not torch.cuda.is_available():
    raise RuntimeError("CUDA is not available inside the uv environment")

print("CUDA device:", torch.cuda.get_device_name(0))
PY

echo
echo "=== Downloading original IndexTTS-2 checkpoints ==="

mkdir -p checkpoints

uv run python - <<'PY'
from huggingface_hub import snapshot_download

snapshot_download(
    repo_id="IndexTeam/IndexTTS-2",
    local_dir="checkpoints"
)

print("IndexTTS-2 checkpoints downloaded.")
PY

echo
echo "=== Copying Serbian files ==="

cp "$PACKAGE/bpe_serbian_13005.model" \
   "$REPO/checkpoints/bpe_serbian_13005.model"

cp "$PACKAGE/config_serbian_13005.yaml" \
   "$REPO/checkpoints/config_serbian_13005.yaml"

cp "$PACKAGE/gpt_serbian_13005_init.pth" \
   "$REPO/checkpoints/gpt_serbian_13005_init.pth"

echo
echo "=== SETUP COMPLETE ==="
df -h /workspace