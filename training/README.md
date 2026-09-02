# Serbian Training

This directory contains the reproducible training pipeline for adapting IndexTTS-2 to Serbian.

The pipeline was prepared and validated locally before renting a remote GPU.

Actual RunPod deployment and full Serbian model training have **not yet been performed**.

---

## Goal

The purpose of this pipeline is to combine:

```text
Serbian language support
+
IndexTTS-2 expressive control
```

The existing IndexTTS-2 setup provides promising control over:

- speaker identity;
- emotion;
- duration;
- pacing.

However, the original model does not provide usable Serbian pronunciation.

The current R&D direction is therefore Serbian language adaptation.

---

## Pipeline

The intended execution order is:

```text
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
```

Each stage has a separate responsibility and validates the things that are critical for that stage.

---

## Stages

### RUNPOD_SETUP.sh

Prepares the remote training environment.

### SERVER_PREFLIGHT.sh

Checks the server environment before expensive processing or training begins.

### PREPARE_PARLASPEECH.sh

Downloads, verifies and extracts the ParlaSpeech source data.

### BUILD_DATASET.py

Builds the canonical Serbian dataset manifest from the prepared ParlaSpeech data and project split manifests.

### RUN_PREPROCESS.sh

Converts the prepared dataset into the format required by the IndexTTS training pipeline.

### GENERATE_GPT_PAIRS.sh

Creates the GPT training and validation manifests.

Expected outputs:

```text
gpt_pairs_train.jsonl
gpt_pairs_val.jsonl
```

### SMOKE_TEST.sh

Runs a short end-to-end training test to prove that the complete training path works.

### BENCHMARK_A40.sh

Runs a controlled GPU benchmark before full training.

The A40 is the current reference GPU, not a hard requirement.

The benchmark measures important runtime characteristics such as:

- training speed;
- peak VRAM;
- checkpoint creation;
- disk usage.

### TRAIN_FULL.sh

Runs the actual long Serbian training process.

This stage includes additional safety mechanisms for:

- resume after interruption;
- checkpoint validation;
- disk-space protection;
- final result validation.

---

## Reliability Principles

The training pipeline follows several rules:

```text
do not trust filenames alone
verify important artifacts

do not overwrite a valid checkpoint directly
write atomically

do not resume blindly
validate checkpoint identity

do not start full training immediately
smoke-test and benchmark first
```

A central project principle is:

> Each stage verifies what is important for that stage.

---

## Current Status

```text
Local pipeline preparation        COMPLETE
Local static validation           COMPLETE
Checkpoint recovery tests         COMPLETE
Training package integrity        COMPLETE
RunPod deployment                 PENDING
Real GPU benchmark                PENDING
Full Serbian training             PENDING
```

The remote training stage is currently waiting for project budget.

---

## Large Artifacts

Large training artifacts are intentionally not stored directly in this Git repository.

Examples include:

- ParlaSpeech audio;
- processed datasets;
- training checkpoints;
- large model weights;
- the packaged IndexTTS training repository;
- temporary caches and logs.

The Git repository contains the reproducible code, configuration and documentation required to rebuild the training environment.
