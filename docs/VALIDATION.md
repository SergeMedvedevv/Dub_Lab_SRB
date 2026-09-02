# Local Validation and Safety Checks

This document records the validation performed on the Serbian IndexTTS-2 training pipeline before real RunPod deployment.

The purpose is to distinguish between:

```text
locally validated engineering
```

and:

```text
real GPU training results
```

The training pipeline has been extensively checked locally, but full Serbian model training has not yet been performed.

---

## Validation Philosophy

The pipeline follows a simple rule:

> A successful command exit is not enough. Important stages should prove their output contract.

Examples:

```text
checkpoint created
≠
checkpoint proven usable
```

and:

```text
trainer returned successfully
≠
training result proven valid
```

Validation was therefore added at several levels:

- static code checks;
- semantic tests;
- simulated failure tests;
- checkpoint recovery tests;
- cross-file contract checks;
- package integrity verification.

---

# 1. Checkpoint Crash / Recovery Test

The trainer checkpoint system was tested with artificial failure scenarios.

Result:

```text
10 / 10 tests passed
```

Tested behavior included:

- normal atomic checkpoint write;
- interruption during `torch.save`;
- failure before atomic replacement;
- preservation of the previous valid checkpoint;
- valid `latest.pth`;
- corrupted checkpoint rejection;
- valid `model_stepN.pth`;
- filename / checkpoint-step mismatch;
- structurally incomplete checkpoints;
- manifest mismatch as a hard failure;
- missing manifest identity as a hard failure.

Result:

```text
ATOMIC WRITE SEMANTICS       SUCCESS
CORRUPTION DETECTION         SUCCESS
MODEL_STEP VALIDATION        SUCCESS
MANIFEST HARD-FAIL CONTRACT  SUCCESS
CHECKPOINT RECOVERY          SUCCESS
```

---

# 2. Completion / Rerun Semantic Test

The trainer was tested for accidental continuation after the requested training target had already been reached.

Result:

```text
12 / 12 tests passed
```

Verified scenarios included:

- fresh training is allowed;
- interrupted current epoch can resume;
- completed epoch target blocks rerun;
- exact `max_steps` target blocks an extra optimizer step;
- training below `max_steps` remains allowed;
- `max_steps=0` remains unlimited;
- normal epoch completion advances the resume epoch;
- step-limited completion preserves the current epoch;
- deliberately increasing `max_steps` allows intentional continuation;
- final `model_step` and `latest.pth` share the same resume semantics;
- old unsafe final-save behavior is absent.

Result:

```text
PRE-TRAIN RERUN GUARD        SUCCESS
EPOCH COMPLETION SEMANTICS   SUCCESS
MAX_STEPS COMPLETION         SUCCESS
FINAL CHECKPOINT SEMANTICS   SUCCESS
```

---

# 3. Disk Guard Semantic Test

The disk-safety mechanism was tested using simulated filesystem conditions.

No real disk filling was required.

Result:

```text
6 / 6 tests passed
```

Verified scenarios:

```text
100 GiB free
40 GiB minimum
5 GiB checkpoint
→ PASS
```

```text
39 GiB free
40 GiB minimum
→ HARD STOP
```

```text
60 GiB free
20 GiB largest checkpoint
dynamic reserve = 80 GiB
→ HARD STOP
```

```text
80 GiB free
80 GiB required
→ PASS
```

Also verified:

- disk guard disabled when configured as `0`;
- negative disk-space configuration rejected.

Result:

```text
MINIMUM 40 GiB FLOOR       SUCCESS
DYNAMIC 4x RESERVE         SUCCESS
BOUNDARY SEMANTICS         SUCCESS
DISABLED MODE              SUCCESS
INVALID CONFIG REJECTION   SUCCESS
```

---

# 4. TRAIN_FULL ↔ Trainer Static Audit

The complete interaction between:

```text
TRAIN_FULL.sh
```

and:

```text
trainers/train_gpt_v2.py
```

was audited after the safety changes were completed.

Result:

```text
142 checks passed
0 failed
```

The audit covered:

- file format;
- input safety;
- cache / temp configuration;
- resume discovery;
- checkpoint fallback;
- atomic checkpoint writes;
- manifest identity;
- completion / rerun behavior;
- disk safety;
- final `latest.pth` validation;
- final `model_stepN.pth` validation;
- cross-file CLI arguments;
- final success ordering;
- removal of older unsafe logic.

Result:

```text
FINAL TRAIN_FULL <-> TRAINER STATIC AUDIT: SUCCESS
```

---

# 5. Training Repository ZIP Verification

The canonical training repository archive:

```text
index-tts-2-train.zip
```

was rebuilt from the final locally validated training repository.

The archive preserved the canonical package layout rather than blindly archiving the entire development directory.

Verification result:

```text
286 / 286 files verified
HASH MISMATCHES: 0
```

The trainer inside the ZIP was compared with the live trainer repository.

Result:

```text
LIVE TRAINER == ZIP TRAINER
```

The archive therefore contains the same trainer implementation that passed the local validation.

---

# 6. Server_Package SHA256 Verification

The final `Server_Package` uses:

```text
SHA256SUMS.txt
```

as an integrity manifest.

The final controlled file set contains:

```text
16 files
```

All hashes were recalculated after the final script and training ZIP changes.

Result:

```text
16 / 16 hashes verified
```

The control list was also checked against the actual package file set.

Result:

```text
PACKAGE FILE SET MATCH   OK
UTF-8 / LF FORMAT        OK
ALL FINAL HASHES         OK
```

---

# 7. PREPARE → BUILD Contract Verification

The first full package audit initially reported two failures related to:

```text
PREPARE_PARLASPEECH.sh
```

not directly referencing:

```text
parlaspeech_sr_split_plan_v3.jsonl
parlaspeech_sr_train_source.jsonl
```

These were determined to be incorrect assumptions in the audit itself.

The actual responsibility split is:

```text
PREPARE_PARLASPEECH.sh
↓
prepare original ParlaSpeech audio
↓
ParlaSpeech/source
```

followed by:

```text
BUILD_DATASET.py
↓
consume:
  parlaspeech_sr_split_plan_v3.jsonl
  parlaspeech_sr_train_source.jsonl
  ParlaSpeech/source
↓
produce:
  parlaspeech_sr_ready.jsonl
```

A dedicated correction audit was performed.

Result:

```text
17 / 17 checks passed
0 failed
```

Confirmed:

```text
PREPARE AUDIO RESPONSIBILITY       OK
BUILD JSONL RESPONSIBILITY         OK
PREPARE -> BUILD PATH HANDOFF      OK
RUNBOOK ORCHESTRATION              OK
PACKAGE HASHES REMAIN FROZEN       OK
```

No package files required modification.

---

# 8. Final Package State

After all corrections and verification:

```text
training scripts          READY
training repository ZIP   READY
SHA256 manifest           READY
RunPod runbook            READY
local safety validation   COMPLETE
```

Important final integrity values were frozen before server deployment.

The package was not modified after the final validation checkpoint.

---

# 9. What These Tests Prove

The local validation provides confidence in:

```text
training package structure
environment handoff
dataset stage boundaries
checkpoint writing
checkpoint recovery
resume safety
dataset identity protection
disk safety
completion semantics
final checkpoint validation
package integrity
```

It also reduces the amount of debugging that should need to be performed while paying for rented GPU time.

---

# 10. What These Tests Do NOT Prove

Local validation does not prove:

- that RunPod deployment will succeed without environment-specific issues;
- that a selected rented GPU will have sufficient performance;
- that the complete ParlaSpeech preprocessing run will finish successfully on the server;
- that full Serbian training will converge;
- that the trained model will produce high-quality Serbian;
- that pronunciation, prosody and expressive control will meet dubbing-quality requirements.

Those questions require real server execution.

---

## Current Validation Boundary

```text
LOCAL ENGINEERING
        ✅ validated

RUNPOD DEPLOYMENT
        ⏳ pending

REAL GPU BENCHMARK
        ⏳ pending

FULL SERBIAN TRAINING
        ⏳ pending

MODEL QUALITY EVALUATION
        ⏳ pending
```

The next validation phase begins when GPU rental budget becomes available.
