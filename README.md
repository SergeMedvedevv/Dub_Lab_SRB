# DubLab SRB

**AI-powered Serbian dubbing research project**

DubLab SRB is an experimental project exploring how modern AI tools can be combined to create high-quality Serbian dubbing for films and video content.

## 🎯 Goal

The current goal is to build a working pipeline capable of taking a short scene from a film and producing a watchable Serbian-dubbed version while preserving the original atmosphere, music and sound effects.

The pipeline will explore:

- Speech recognition and transcription
- Speaker detection and diarization
- Dialogue separation
- English → Serbian translation
- Voice cloning and Serbian TTS
- Timing and synchronization
- Audio reconstruction and mixing
- Workflow automation

## 🧪 Current stage

DubLab SRB currently has two parallel development tracks.

### Prototype V1

A working Serbian dubbing baseline has been built and tested on real movie material.

The pipeline already includes:

- dialogue / background separation;
- WhisperX transcription and timestamps;
- speaker diarization;
- structured dubbing scripts;
- Serbian translation;
- Serbian TTS generation;
- timeline reconstruction;
- duration analysis and correction.

V1 is the current stable and repeatable baseline.

### Experimental V2

The second research direction focuses on preserving more of the original acting performance:

- speaker identity;
- emotion;
- pacing;
- pauses;
- approximate duration.

TED-TTS / IndexTTS-2 has shown promising local control over speaker identity, emotion and duration.

The current blocker is Serbian language support.

The next major R&D objective is therefore:

**Serbian expressive speech with IndexTTS-style performance control.**
## ⚠️ Status

DubLab SRB is currently an experimental R&D project and is not production-ready.
