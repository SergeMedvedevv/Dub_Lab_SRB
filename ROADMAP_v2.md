# DubLab SRB — Roadmap

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
- [x] Confirm no suitable public checkpoint was found
- [x] Research community low-resource language adaptation
- [x] Identify tokenizer + LoRA / GPT fine-tuning as a realistic path

## Serbian V0

- [ ] Find suitable Serbian speech datasets
- [ ] Check licenses and quality
- [ ] Prepare transcripts and metadata
- [ ] Build / extend Serbian tokenizer
- [ ] Prepare training pipeline
- [ ] Rent 24 GB+ GPU
- [ ] Run first Serbian LoRA experiment
- [ ] Test Serbian pronunciation
- [ ] Test emotion control
- [ ] Test duration control
- [ ] Test voice cloning

---

# Phase 5 — Complete V2 Prototype

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

- [ ] Complete project journal
- [ ] Create `WORKFLOW.md` / `RUNBOOK.md`
- [ ] Add copy-ready commands
- [ ] Explain editable parameters
- [ ] Document UVR
- [ ] Document WhisperX
- [ ] Document diarization
- [ ] Document translation workflow
- [ ] Document expressive speech workflow
- [ ] Document final mixing

---

# Phase 7 — Project Knowledge Base

- [ ] Create Obsidian vault
- [ ] Create project mind map
- [ ] Add V1 / V2 branches
- [ ] Add model research
- [ ] Add Serbian adaptation branch
- [ ] Add experiments
- [ ] Add Business & Funding section

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
