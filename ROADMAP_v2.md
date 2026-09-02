# DubLab SRB — Roadmap_v2

## Current Goal

Build a watchable Serbian-dubbed movie fragment and develop a modular dubbing pipeline that preserves:

- translation quality;
- speaker identity;
- approximate timing;
- pauses;
- emotional delivery;
- overall performance shape.

**Quality first. Automation later.**

---

# Phase 1 — Prototype V1

- [x] Select a real movie fragment
- [x] Separate dialogue and background with UVR
- [x] Transcribe dialogue with WhisperX
- [x] Generate accurate timestamps
- [x] Separate speakers with pyannote
- [x] Map speakers to characters
- [x] Create structured dubbing CSV
- [x] Translate the scene into Serbian
- [x] Generate Serbian TTS automatically
- [x] Place generated dialogue on the original timeline
- [x] Build and watch the first V1 scene
- [x] Analyze dialogue duration mismatch
- [x] Test time-stretch correction

### V1 Status

**Working baseline.**

Main limitation:

Normal TTS does not preserve the original pacing and acting rhythm well enough, especially on long lines.

---

# Phase 2 — Expressive Dubbing Research

Goal:

Preserve more of the original performance:

- pauses;
- pacing;
- emotion;
- loudness / quiet delivery;
- approximate duration;
- speaker identity.

## Commercial Benchmarks

- [x] ElevenLabs Dubbing
- [x] Rask AI
- [x] CAMB.AI
- [x] Perso AI availability check
- [x] Dubformer research
- [ ] Dubformer real test when affordable

### Current Benchmark

**ElevenLabs Dubbing currently gives the best tested performance preservation.**

Commercial systems remain useful mainly as quality references.

---

# Phase 3 — Open / Local V2

## Meta SeamlessExpressive

- [x] Receive Hugging Face access
- [x] Test available Spaces
- [x] Confirm public demos fail because of memory limits
- [ ] Run on rented 24 GB+ GPU
- [ ] Compare with ElevenLabs benchmark

## TED-TTS / IndexTTS-2

- [x] Install TED-TTS locally
- [x] Configure CUDA
- [x] Run inference on RTX 2080
- [x] Test emotion reference
- [x] Test manual emotion control
- [x] Test duration control
- [x] Test speaker reference / voice cloning
- [x] Combine voice + emotion + duration
- [x] Obtain a strong English test result
- [x] Test Serbian input
- [x] Confirm Serbian pronunciation is not supported
- [ ] Test more local duration / prosody control
- [ ] Continue controlled experiments

### Current TED-TTS Status

Promising.

The combination:

**speaker reference + emotion control + duration control**

produced the strongest local V2 result so far.

Main limitation:

**Serbian language support is missing.**

---

# Phase 4 — Serbian Adaptation

- [x] Check Serbian / Croatian / Bosnian support
- [x] Search for existing IndexTTS-2 checkpoints
- [x] Confirm no suitable public Serbian checkpoint was found
- [x] Research low-resource language adaptation
- [x] Identify tokenizer + GPT fine-tuning as a realistic path
- [x] Select ParlaSpeech as the primary initial Serbian dataset
- [x] Prepare canonical dataset split / source manifests
- [x] Build / extend Serbian tokenizer
- [x] Prepare Serbian training configuration
- [x] Prepare initial Serbian GPT checkpoint
- [x] Build reproducible Serbian training pipeline
- [x] Build reproducible RunPod server package
- [x] Add local validation and recovery tests
- [x] Freeze training package with SHA256 integrity checks

## Serbian V0 — Training Preparation

Current locally prepared pipeline:

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

### Local preparation

- [x] Prepare ParlaSpeech download / extraction stage
- [x] Add dataset download integrity checks
- [x] Prepare deterministic dataset builder
- [x] Add restart-safe dataset output
- [x] Prepare IndexTTS preprocessing stage
- [x] Prepare GPT train / validation pair generation
- [x] Prepare end-to-end smoke test
- [x] Prepare GPU benchmark stage
- [x] Prepare full-training stage
- [x] Add manifest fingerprinting
- [x] Add safe resume / checkpoint fallback
- [x] Add atomic checkpoint writes
- [x] Add training completion / rerun protection
- [x] Add disk-space safety
- [x] Add final checkpoint validation
- [x] Rebuild canonical training repository ZIP
- [x] Verify packaged trainer against live trainer
- [x] Verify final Server_Package SHA256 manifest

### Local validation

- [x] Checkpoint crash / recovery tests — 10/10
- [x] Completion / rerun semantic tests — 12/12
- [x] Disk guard semantic tests — 6/6
- [x] TRAIN_FULL ↔ trainer static audit — 142/142
- [x] Training ZIP verification — 286/286 files
- [x] Server package hash verification — 16/16 files
- [x] PREPARE → BUILD contract correction audit — 17/17

### Remote execution

- [ ] Rent suitable GPU
- [ ] Deploy final Server_Package to RunPod
- [ ] Run real `RUNPOD_SETUP.sh`
- [ ] Pass real `SERVER_PREFLIGHT.sh`
- [ ] Prepare full ParlaSpeech dataset on server
- [ ] Run real end-to-end smoke test
- [ ] Run GPU benchmark
- [ ] Decide whether selected GPU is suitable
- [ ] Run first full Serbian training experiment
- [ ] Verify resume behavior during real training
- [ ] Download final Serbian checkpoint
- [ ] Test Serbian pronunciation
- [ ] Test emotion control
- [ ] Test duration control
- [ ] Test voice cloning

### Current Serbian Training Status

```text
LOCAL TRAINING ENGINEERING
=
READY / VALIDATED

REAL GPU EXECUTION
=
PENDING

FULL SERBIAN MODEL
=
NOT TRAINED YET
```

The current blocker is not local pipeline preparation.

The next blocker is:

```text
GPU rental budget
```

---

# Phase 5 — Complete V2 Prototype

This phase begins after a usable Serbian expressive model exists.

- [ ] Generate expressive Serbian ALICE lines
- [ ] Generate BILL lines
- [ ] Compare V1 vs V2
- [ ] Correct missed ASR lines
- [ ] Reconstruct the full dialogue timeline
- [ ] Mix with the original background
- [ ] Assemble the final movie fragment
- [ ] Evaluate overall watchability

---

# Phase 6 — Documentation

## Core documentation

- [x] Create `WORKFLOW.md`
- [x] Create RunPod training runbook
- [x] Document Serbian training architecture
- [x] Document local training validation
- [x] Add copy-ready server execution order
- [x] Document V1 production workflow
- [x] Document UVR stage
- [x] Document WhisperX / alignment stage
- [x] Document diarization stage
- [x] Document translation workflow
- [x] Document timing / reconstruction workflow
- [x] Document final mixing workflow

## Ongoing documentation

- [ ] Continue project journal as development continues
- [ ] Continue documenting expressive V2 experiments
- [ ] Document real RunPod deployment after first server run
- [ ] Document real benchmark results
- [ ] Document final Serbian training results
- [ ] Document model-quality evaluation

---

# Phase 7 — Project Knowledge Base

- [x] Create Obsidian vault
- [x] Separate V1 / V2 knowledge areas
- [x] Add model research area
- [x] Add Serbian adaptation area
- [x] Add Serbian dataset research
- [x] Add Business section
- [x] Synchronize Obsidian between PC and Android
- [ ] Continue meaningful cross-linking
- [ ] Expand project mind map
- [ ] Keep GitHub and Obsidian responsibilities separated

### Knowledge Base Principle

```text
Journal
=
history

Workflow
=
repeatable instructions

Roadmap
=
future plan

Obsidian
=
connected project knowledge

GitHub
=
stable code + public documentation
```

---


# Phase 8 — Testing on Other Material

After the first complete prototype:

- [ ] Terminator 2
- [ ] Ben-Hur (1959)
- [ ] Fast dialogue
- [ ] Quiet dialogue
- [ ] Whisper
- [ ] Shouting
- [ ] Emotional dialogue
- [ ] Multiple speakers
- [ ] Dialogue over music and effects

---

# Long-Term Architecture

`Source Film`

↓

`Audio Separation`

↓

`ASR + Alignment`

↓

`Speaker Diarization`

↓

`Translation`

↓

`Performance / Emotion Control`

↓

`Duration Control`

↓

`Serbian Speech Generation`

↓

`Voice Identity`

↓

`Timeline Reconstruction`

↓

`Original Background Mix`

↓

`Final Dubbed Film`

---

# Project Principle

**Do not search for one model that solves everything.**

Use the strongest available component for each stage.

**First prove quality. Then make the process reproducible. Then automate it.**
