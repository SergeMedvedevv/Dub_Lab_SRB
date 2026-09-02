# DubLab SRB — Roadmap

> ⚠️ Legacy roadmap.
>
> This file preserves an earlier development plan.
> The current roadmap is available in `ROADMAP_v2.md`.
## Current Goal

Build a complete **3–5 minute Serbian-dubbed film scene** using the best currently available tools.

Quality comes first. Full automation comes later.

---

## Phase 1 — Working Prototype

- [x] Research Serbian TTS solutions
- [x] Test F5-TTS Serbian
- [x] Test Fish Audio
- [x] Test ElevenLabs Serbian TTS
- [x] Begin ElevenLabs API integration with n8n
- [ ] Move n8n to a suitable European VPS
- [ ] Complete ElevenLabs API test
- [ ] Select a 3–5 minute test scene
- [ ] Extract original audio
- [ ] Separate dialogue from music and sound effects
- [ ] Transcribe dialogue with timestamps
- [ ] Detect individual speakers
- [ ] Translate dialogue into Serbian
- [ ] Assign Serbian voices to characters
- [ ] Generate Serbian dialogue
- [ ] Synchronize generated dialogue
- [ ] Reconstruct and mix the soundtrack
- [ ] Produce the first finished Serbian-dubbed scene

## Phase 2 — Evaluation

Test the pipeline on several different scenes:

- Two-person dialogue
- Emotional dialogue
- Multiple speakers
- Fast conversation
- Dialogue with music and sound effects

Compare quality, timing, pronunciation and consistency.

## Phase 3 — Automation

Gradually automate proven stages using n8n and supporting tools.

## Phase 4 — Serbian TTS Research

Explore:

- Serbian speech datasets
- Fine-tuning existing multilingual models
- Fish Audio fine-tuning
- Improved Serbian pronunciation and prosody
- Possibility of an independent Serbian TTS model

---

## Principle

**First prove the quality. Then automate it.**
