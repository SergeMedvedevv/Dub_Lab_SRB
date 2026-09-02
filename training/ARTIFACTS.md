# External Training Artifacts

This document records the important training artifacts that are required by the Serbian IndexTTS-2 pipeline but are intentionally **not stored directly in this Git repository**.

The purpose is reproducibility.

A future setup should be able to answer:

```text
What file is required?
Why is it required?
Where did it come from?
How can its identity be verified?
```

Large model files, datasets and packaged repositories are kept outside normal Git history.

---

## Why These Files Are Not Stored in Git

Some project artifacts are too large or unsuitable for a normal Git repository.

Examples include:

- model checkpoints;
- packaged training repositories;
- large JSONL dataset manifests;
- raw speech datasets;
- processed training data;
- generated checkpoints.

Git stores:

```text
code
configuration
documentation
pipeline logic
```

External storage keeps:

```text
large models
datasets
training outputs
packaged binaries
```

Artifact identity is verified using:

```text
SHA256
```

---

# 1. Serbian Tokenizer

## `bpe_serbian_13005.model`

**Role**

Serbian tokenizer used by the IndexTTS-2 Serbian adaptation pipeline.

It represents the tokenizer / vocabulary prepared for Serbian training.

```text
Serbian text
↓
bpe_serbian_13005.model
↓
token representation
↓
GPT training
```

**Stored in Git**

```text
NO
```

**Required for training**

```text
YES
```

**Canonical Server_Package name**

```text
bpe_serbian_13005.model
```

**Verification**

The canonical SHA256 is stored in the final:

```text
Server_Package/SHA256SUMS.txt
```

Use that checksum to verify any restored copy before training.

---

# 2. Serbian GPT Initial Checkpoint

## `gpt_serbian_13005_init.pth`

**Role**

Initial GPT checkpoint used as the starting point for Serbian training.

This is not the final Serbian model.

It is the prepared initialization state from which the Serbian training experiment begins.

```text
initial Serbian GPT state
↓
ParlaSpeech training
↓
trained Serbian GPT checkpoint
```

**Stored in Git**

```text
NO
```

**Required for training**

```text
YES
```

**Canonical Server_Package name**

```text
gpt_serbian_13005_init.pth
```

**Verification**

The canonical SHA256 is stored in:

```text
Server_Package/SHA256SUMS.txt
```

A checkpoint with the same filename but a different SHA256 must not be assumed to be the same training artifact.

---

# 3. Frozen IndexTTS Training Repository

## `index-tts-2-train.zip`

**Role**

Frozen copy of the IndexTTS-2 training repository used by the Serbian training pipeline.

The archive exists so a future RunPod instance receives:

```text
the exact training code prepared locally
```

rather than:

```text
whatever version happens to exist upstream later
```

**Stored in Git**

```text
NO
```

The important project scripts and documentation are stored in Git separately, but the complete packaged training repository is kept as an external artifact.

**Required for the current RunPod setup**

```text
YES
```

**Canonical Server_Package name**

```text
index-tts-2-train.zip
```

**Final verified SHA256**

```text
e0644856fc0d255000f7f6987a69ba524850a60291a93976f144c30c29514e59
```

**Final archive verification**

```text
286 / 286 files verified
HASH MISMATCHES: 0
```

The packaged trainer was also verified against the live locally validated trainer.

```text
LIVE TRAINER == ZIP TRAINER
```

---

# 4. Canonical Trainer Identity

The most important modified training file inside the frozen repository is:

```text
trainers/train_gpt_v2.py
```

This file contains the Serbian training safety and recovery work, including:

- manifest identity;
- checkpoint validation;
- atomic checkpoint writes;
- resume fallback;
- completion / rerun protection;
- disk safety;
- final checkpoint semantics.

**Final verified SHA256**

```text
badccc8322102ac55bb518ba98143d5e9562364fa64be3ab52a339fec48a73b0
```

The same trainer hash was verified in:

```text
live local training repository
=
packaged index-tts-2-train.zip
```

---

# 5. Serbian Split Plan

## `parlaspeech_sr_split_plan_v3.jsonl`

**Role**

Canonical plan defining the selected ParlaSpeech material used for the Serbian dataset build.

The purpose of the split plan is reproducibility.

Instead of selecting training material again in the future:

```text
same split plan
+
same source data
↓
same intended Serbian dataset selection
```

**Stored in Git**

```text
NO
```

The file is intentionally excluded because it is a large generated dataset artifact.

**Required for dataset construction**

```text
YES
```

**Consumed by**

```text
BUILD_DATASET.py
```

**Canonical Server_Package name**

```text
parlaspeech_sr_split_plan_v3.jsonl
```

**Verified record count**

```text
304450
```

**Verification**

Use the SHA256 stored in the final:

```text
Server_Package/SHA256SUMS.txt
```

---

# 6. Serbian Source Manifest

## `parlaspeech_sr_train_source.jsonl`

**Role**

Canonical source manifest used together with the split plan and prepared ParlaSpeech audio.

Dataset construction uses:

```text
parlaspeech_sr_split_plan_v3.jsonl
+
parlaspeech_sr_train_source.jsonl
+
ParlaSpeech/source
↓
BUILD_DATASET.py
↓
parlaspeech_sr_ready.jsonl
```

**Stored in Git**

```text
NO
```

**Required for dataset construction**

```text
YES
```

**Canonical Server_Package name**

```text
parlaspeech_sr_train_source.jsonl
```

**Verified record count**

```text
290778
```

**Verification**

Use the SHA256 stored in:

```text
Server_Package/SHA256SUMS.txt
```

---

# 7. Generated Ready Dataset Manifest

## `parlaspeech_sr_ready.jsonl`

**Role**

Generated dataset manifest created on the training machine after the original ParlaSpeech data has been prepared.

Created by:

```text
BUILD_DATASET.py
```

from:

```text
split plan
+
source manifest
+
ParlaSpeech audio
```

**Stored in Git**

```text
NO
```

**Stored in the original Server_Package**

```text
NO
```

This is a generated artifact.

It should be recreated from the canonical inputs.

The expected pipeline is:

```text
PREPARE_PARLASPEECH.sh
↓
ParlaSpeech/source

BUILD_DATASET.py
↓
parlaspeech_sr_ready.jsonl
```

---

# 8. Generated GPT Pair Manifests

## `gpt_pairs_train.jsonl`

## `gpt_pairs_val.jsonl`

**Role**

Direct training and validation manifests consumed by the GPT trainer.

Generated after:

```text
dataset construction
↓
IndexTTS preprocessing
↓
GPT pair generation
```

**Stored in Git**

```text
NO
```

**Canonical source**

They should be regenerated using:

```text
RUN_PREPROCESS.sh
↓
GENERATE_GPT_PAIRS.sh
```

These manifests are also fingerprinted by the trainer before training.

Checkpoint metadata records information including:

```text
path
record count
language
file size
SHA256
```

This prevents an old checkpoint from being silently resumed against different manifests.

---

# 9. ParlaSpeech Audio

## `ParlaSpeech/source`

**Role**

Original Serbian speech material used for the first adaptation experiment.

**Stored in Git**

```text
NO
```

**Stored in Server_Package**

```text
NO
```

The original data is prepared on the training machine by:

```text
PREPARE_PARLASPEECH.sh
```

The preparation stage includes download integrity verification before extraction.

Expected location on the training machine:

```text
/workspace/DubLabSRB/ParlaSpeech/source
```

---

# 10. Processed Dataset

The IndexTTS preprocessing stage generates additional processed training data.

**Stored in Git**

```text
NO
```

**Reason**

It is generated, potentially large and reproducible from earlier pipeline stages.

Recreate it using:

```text
RUN_PREPROCESS.sh
```

rather than keeping it in Git history.

---

# 11. Training Checkpoints

Generated training checkpoints include files such as:

```text
latest.pth
model_stepN.pth
```

**Stored in Git**

```text
NO
```

These are training outputs.

They may become extremely large and change throughout training.

The training system protects them using:

- atomic writes;
- structural validation;
- manifest identity;
- resume fallback;
- disk-space guards.

Important successful checkpoints should be archived separately after real GPU training.

---

# 12. Server_Package Integrity Manifest

The final local training package contains:

```text
SHA256SUMS.txt
```

This file is the canonical integrity manifest for the prepared server package.

At the final local checkpoint:

```text
16 / 16 controlled files verified
```

The final SHA256 of `SHA256SUMS.txt` itself was:

```text
7abf453d1a547a8f104298b5b0d775e502d8c5e729e7f8b170c31862fab51abf
```

This value identifies the final locally validated package state prepared before RunPod deployment.

---

# 13. Important Frozen Hashes

The following hashes identify the most important final training components.

| Artifact | SHA256 |
|---|---|
| `index-tts-2-train.zip` | `e0644856fc0d255000f7f6987a69ba524850a60291a93976f144c30c29514e59` |
| `trainers/train_gpt_v2.py` | `badccc8322102ac55bb518ba98143d5e9562364fa64be3ab52a339fec48a73b0` |
| `TRAIN_FULL.sh` | `56605d335a08024aaaa3d592f4c3b7bb4c5fc3d9f43ef73df65aa84b77addfbd` |
| `SHA256SUMS.txt` | `7abf453d1a547a8f104298b5b0d775e502d8c5e729e7f8b170c31862fab51abf` |

These values correspond to the final locally validated pre-RunPod state.

---

# 14. Restoring the Project Later

For a future reproduction of the Serbian training experiment:

```text
1. Clone this Git repository.

2. Recover the external Server_Package artifacts.

3. Verify all external files against SHA256SUMS.txt.

4. Confirm the frozen training ZIP identity.

5. Follow:
   training/RUNPOD_RUNBOOK.md

6. Run:
   RUNPOD_SETUP.sh

7. Run:
   SERVER_PREFLIGHT.sh

8. Continue through the staged pipeline.

9. Do not jump directly to TRAIN_FULL.sh.

10. Smoke-test and benchmark the real GPU first.
```

The intended execution path remains:

```text
RUNPOD_SETUP
↓
SERVER_PREFLIGHT
↓
PREPARE_PARLASPEECH
↓
BUILD_DATASET
↓
RUN_PREPROCESS
↓
GENERATE_GPT_PAIRS
↓
SMOKE_TEST
↓
BENCHMARK
↓
TRAIN_FULL
```

---

# 15. Reproducibility Boundary

The Git repository alone is intentionally **not** a complete binary archive of the project.

Instead:

```text
Git
=
code
+
configuration
+
documentation
+
history
```

while:

```text
external archive
=
large model artifacts
+
canonical dataset manifests
+
frozen training repository
+
future trained checkpoints
```

Together with the recorded SHA256 values, these form the reproducible project state.

---

## Related Documentation

- [Serbian Training](README.md)
- [RunPod Runbook](RUNPOD_RUNBOOK.md)
- [Training Pipeline Architecture](../docs/TRAINING_PIPELINE.md)
- [Local Validation and Safety Checks](../docs/VALIDATION.md)
- [Project Journal](../JOURNAL.md)
- [Roadmap](../ROADMAP_v2.md)
