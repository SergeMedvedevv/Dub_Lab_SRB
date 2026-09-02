# Serbian Training

This directory contains the reproducible training pipeline for adapting
IndexTTS-2 to Serbian.

Current execution order:

RUNPOD_SETUP.sh
↓
SERVER_PREFLIGHT.sh
↓
PREPARE_PARLASPEECH.sh
↓
BUILD_DATASET.py
↓
RUN_PREPROCESS.sh
↓
GENERATE_GPT_PAIRS.sh
↓
SMOKE_TEST.sh
↓
BENCHMARK_A40.sh
↓
TRAIN_FULL.sh

The pipeline has been prepared and validated locally.

Actual RunPod deployment and full GPU training have not yet been performed.
