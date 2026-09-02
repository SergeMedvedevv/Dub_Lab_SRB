# Serbian Training Pipeline Architecture

This document describes the architecture of the Serbian IndexTTS-2 training pipeline used in DubLab SRB.

It explains **how the training system is structured and why it was designed this way**.

For the exact RunPod execution procedure, see:

```text
training/RUNPOD_RUNBOOK.md
```

---

## Goal

The objective is to adapt IndexTTS-2 to Serbian while preserving the expressive-control capabilities that made the model interesting for film dubbing.

The target is:

```text
Serbian pronunciation
+
speaker identity
+
emotion
+
duration / pacing control
```

The original IndexTTS-2 setup showed promising expressive control but did not produce usable Serbian pronunciation.

Therefore the problem is not simply voice cloning.

It is a language-adaptation problem.

---

## High-Level Architecture

The training pipeline is divided into independent stages:

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

The central engineering principle is:

> Each stage verifies what is important for that stage.

A later stage should not blindly assume that everything before it worked correctly.

---

# 1. Environment Setup

## RUNPOD_SETUP.sh

The setup stage prepares the rented GPU environment.

Its responsibility is to establish the expected training environment before any expensive processing or training begins.

Conceptually:

```text
empty RunPod instance
↓
project directories
↓
Python environment
↓
training repository
↓
dependencies
↓
Serbian training artifacts
↓
ready for preflight
```

The training repository is packaged separately so the server receives the exact code that was prepared and tested locally.

---

# 2. Server Validation

## SERVER_PREFLIGHT.sh

The preflight stage verifies that the server is suitable for the pipeline.

It checks critical assumptions such as:

```text
Python
CUDA
PyTorch
required files
training repository
tokenizer
configuration
initial checkpoint
storage
```

The purpose is to detect environment problems before GPU time is spent on dataset processing or training.

---

# 3. ParlaSpeech Preparation

## PREPARE_PARLASPEECH.sh

ParlaSpeech is the primary dataset source for the initial Serbian adaptation experiment.

This stage owns the original dataset preparation.

Its responsibilities include:

```text
download
↓
integrity verification
↓
archive extraction
↓
ParlaSpeech/source
```

Dataset download and dataset construction are intentionally separate responsibilities.

---

# 4. Canonical Serbian Dataset

## BUILD_DATASET.py

The dataset builder combines:

```text
ParlaSpeech source audio
+
canonical split plan
+
canonical source manifest
```

to create:

```text
parlaspeech_sr_ready.jsonl
```

The canonical package inputs are:

```text
parlaspeech_sr_split_plan_v3.jsonl
parlaspeech_sr_train_source.jsonl
```

The ready manifest becomes the boundary between raw dataset preparation and IndexTTS-specific preprocessing.

---

## Restart-Safe Dataset Construction

Long dataset operations should not publish incomplete output.

The builder therefore uses a temporary-output strategy:

```text
build temporary output
↓
validate result
↓
promote temporary output
↓
publish final manifest
```

This prevents later stages from accidentally consuming a partially written dataset manifest.

---

# 5. IndexTTS Preprocessing

## RUN_PREPROCESS.sh

The ready Serbian manifest is transformed into data suitable for the IndexTTS training pipeline.

Conceptually:

```text
parlaspeech_sr_ready.jsonl
↓
IndexTTS preprocessing
↓
processed Serbian dataset
```

This stage is separated from dataset construction so preprocessing failures do not require rebuilding the original dataset selection.

---

# 6. GPT Training Pairs

## GENERATE_GPT_PAIRS.sh

After preprocessing, GPT training and validation manifests are generated.

Expected outputs:

```text
gpt_pairs_train.jsonl
gpt_pairs_val.jsonl
```

These files become the direct dataset inputs for GPT training.

The resulting chain is:

```text
ParlaSpeech
↓
canonical ready manifest
↓
preprocessing
↓
GPT pair generation
↓
train / validation manifests
↓
trainer
```

---

# 7. Serbian Training Artifacts

The Serbian adaptation uses explicit model-side artifacts.

Important examples include:

```text
bpe_serbian_13005.model
config_serbian_13005.yaml
gpt_serbian_13005_init.pth
```

Their roles are approximately:

```text
bpe_serbian_13005.model
→ Serbian tokenizer

config_serbian_13005.yaml
→ Serbian training configuration

gpt_serbian_13005_init.pth
→ initial GPT training checkpoint
```

These artifacts are treated as known inputs rather than arbitrary files found in a development directory.

---

# 8. Smoke Test

## SMOKE_TEST.sh

The smoke test is a short end-to-end proof that the training path works.

It is not intended to evaluate model quality.

It checks the technical pipeline:

```text
data
↓
preprocessing
↓
GPT pairs
↓
trainer
↓
optimizer steps
↓
checkpoint
```

A successful process exit alone is not considered sufficient.

The expected training artifacts must also be produced and validated.

---

# 9. GPU Benchmark

## BENCHMARK_A40.sh

The benchmark stage evaluates the selected GPU before full training.

The NVIDIA A40 is the current reference GPU, but the pipeline is not intended to depend permanently on one specific GPU model.

The benchmark records information such as:

```text
training speed
peak VRAM
checkpoint behavior
disk usage
```

The intended decision process is:

```text
new GPU
↓
preflight
↓
smoke test
↓
benchmark
↓
measure real behavior
↓
decide whether full training is appropriate
```

This allows the project to adapt if the originally planned GPU is unavailable.

---

# 10. Full Training

## TRAIN_FULL.sh

The full-training stage performs the actual long-running Serbian adaptation.

Because this process may run for many hours or longer, reliability is significantly more important here than during a short smoke test.

The full-training path includes additional protection around:

- resume behavior;
- checkpoint integrity;
- dataset identity;
- disk space;
- completion semantics;
- final result validation.

---

# 11. Manifest Identity

A checkpoint should not be resumed blindly against a different training dataset.

The training system therefore records dataset identity information.

The manifest fingerprint includes information such as:

```text
path
record count
languages
file size
SHA256
```

Before resume, the stored manifest identity is compared with the current manifests.

The rule is:

```text
same manifests
→ resume allowed

different manifests
→ hard stop
```

A manifest mismatch is not treated as ordinary checkpoint corruption.

The trainer must not silently fall back to another checkpoint from an unknown dataset state.

---

# 12. Atomic Checkpoints

Long training should survive interruption without destroying the last valid checkpoint.

Checkpoint writing therefore uses an atomic-write strategy:

```text
existing valid checkpoint
↓
write temporary checkpoint
↓
flush
↓
fsync
↓
atomic replacement
↓
new valid checkpoint
```

If the process fails during the temporary write:

```text
old checkpoint remains valid
```

instead of being replaced by a partially written file.

---

# 13. Resume and Fallback

Automatic resume does not rely only on:

```text
latest.pth
```

The trainer can also inspect retained:

```text
model_stepN.pth
```

checkpoints.

The intended behavior is:

```text
latest.pth
↓
valid?
├─ yes → resume
└─ no
   ↓
newest model_stepN.pth
↓
validate
↓
resume
```

Checkpoint candidates are checked for structural validity before use.

Explicitly selecting a checkpoint is different:

```text
--resume /specific/checkpoint.pth
```

means:

```text
use this checkpoint
or fail
```

No silent fallback should occur when a specific checkpoint was requested.

---

# 14. Completion / Rerun Safety

A successfully completed training run should not accidentally perform another optimizer step simply because the script was launched again.

Two cases are protected.

## Epoch target already completed

```text
saved resume epoch >= requested epochs
↓
training target already satisfied
↓
do not enter training loop
```

## max_steps already completed

```text
saved global step >= requested max_steps
↓
training target already satisfied
↓
do not execute step N+1
```

This prevents accidental continuation after a run has already reached its requested target.

---

# 15. Disk Safety

The full training script performs a free-space check before training starts.

The current default floor is:

```text
40 GiB
```

The trainer also checks disk space before checkpoint writes.

The runtime reserve is based on:

```text
max(
    configured minimum free space,
    4 × largest existing checkpoint
)
```

The dynamic reserve exists because atomic checkpointing may temporarily require space for multiple checkpoint files at the same time.

The goal is to stop **before** a dangerous checkpoint write when available disk space becomes insufficient.

---

# 16. Final Training Validation

The message:

```text
TRAINING COMPLETE
```

is deliberately placed behind final validation.

The full-training stage verifies the final:

```text
latest.pth
```

and corresponding:

```text
model_stepN.pth
```

before declaring success.

Validation includes checks such as:

```text
checkpoint can be loaded
required training state exists
epoch / step metadata is valid
training target was reached
dataset identity matches
fallback model_step exists
fallback model_step can be loaded
```

The intention is:

```text
trainer process returned
≠
training proven successful
```

Instead:

```text
trainer returned
+
final checkpoints validated
=
TRAINING COMPLETE
```

---

# 17. Integrity and Reproducibility

The server package uses SHA256 checks for controlled artifacts.

This provides a reproducible boundary between local preparation and remote deployment.

The principle is:

```text
same filename
≠
same artifact
```

while:

```text
filename
+
expected SHA256
=
known artifact
```

The packaged training repository is also built from the locally validated training code.

---

# 18. Local Validation

Before real RunPod deployment, multiple local validation layers were performed.

These included:

```text
checkpoint crash / recovery tests
completion / rerun semantic tests
disk-guard semantic tests
TRAIN_FULL ↔ trainer static audit
training ZIP verification
Server_Package SHA256 verification
final package audit
```

This work is intended to reduce expensive debugging time on rented GPU infrastructure.

---

# 19. What Has Not Been Proven Yet

The local preparation does **not** mean that the complete training experiment has already succeeded.

The following stages still require real rented GPU execution:

```text
RunPod deployment
real server preflight
real dataset preparation on server
real smoke training
real GPU benchmark
full Serbian training
final Serbian model evaluation
```

This distinction is intentional.

The project records separately:

```text
locally validated engineering
```

and:

```text
real GPU training result
```

---

# 20. Current Status

```text
Server training architecture       READY
Dataset preparation pipeline       READY
Smoke-test pipeline                READY
GPU benchmark pipeline             READY
Full-training safety               READY
Local package validation           COMPLETE

RunPod deployment                  PENDING
Real GPU benchmark                 PENDING
Full Serbian training              PENDING
Serbian model evaluation           PENDING
```

The next major execution stage begins when GPU rental budget becomes available.

---

## Related Files

```text
training/README.md
training/RUNPOD_RUNBOOK.md
training/RUNPOD_SETUP.sh
training/SERVER_PREFLIGHT.sh
training/PREPARE_PARLASPEECH.sh
training/BUILD_DATASET.py
training/RUN_PREPROCESS.sh
training/GENERATE_GPT_PAIRS.sh
training/SMOKE_TEST.sh
training/BENCHMARK_A40.sh
training/TRAIN_FULL.sh
training/config_serbian_13005.yaml
```
