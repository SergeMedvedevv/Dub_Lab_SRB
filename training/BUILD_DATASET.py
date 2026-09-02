#!/usr/bin/env python3

import json
import subprocess
from pathlib import Path

ROOT = Path("/workspace/DubLabSRB")

PACKAGE = ROOT / "Server_Package"
AUDIO_ROOT = ROOT / "ParlaSpeech" / "source"
CLIPS_ROOT = ROOT / "ParlaSpeech" / "clips"
MANIFEST_ROOT = ROOT / "manifests"

PLAN = PACKAGE / "parlaspeech_sr_split_plan_v3.jsonl"
SOURCE_MANIFEST = PACKAGE / "parlaspeech_sr_train_source.jsonl"

OUT = MANIFEST_ROOT / "parlaspeech_sr_ready.jsonl"
TMP_OUT = MANIFEST_ROOT / "parlaspeech_sr_ready.jsonl.tmp"

CLIPS_ROOT.mkdir(parents=True, exist_ok=True)
MANIFEST_ROOT.mkdir(parents=True, exist_ok=True)

print("Loading source durations...")

source_duration = {}

with SOURCE_MANIFEST.open("r", encoding="utf-8") as f:
    for line in f:
        x = json.loads(line)
        source_duration[x["audio"]] = float(x.get("duration") or 0)

print("Sources:", len(source_duration))

# Determine where the archive actually placed the audio tree.
first_audio = next(iter(source_duration))

direct = AUDIO_ROOT / first_audio

if direct.exists():
    AUDIO_BASE = AUDIO_ROOT
else:
    print("Detecting extracted audio root...")

    first_name = Path(first_audio).name
    matches = list(AUDIO_ROOT.rglob(first_name))

    if not matches:
        raise FileNotFoundError(
            f"Cannot locate first source audio: {first_audio}"
        )

    found = matches[0]

    # Strip source_audio path components from the detected file path.
    base = found
    for _ in Path(first_audio).parts:
        base = base.parent

    AUDIO_BASE = base

print("AUDIO BASE:", AUDIO_BASE)

written = 0
clips_created = 0
original_used = 0
missing = 0
hours = 0.0

with PLAN.open("r", encoding="utf-8") as fin, \
     TMP_OUT.open("w", encoding="utf-8") as fout:

    for line in fin:

        x = json.loads(line)

        source_rel = x["source_audio"]
        original_duration = source_duration.get(source_rel)

        if original_duration is None:
            raise RuntimeError(
                f"Source missing from original manifest: {source_rel}"
            )

        source_path = AUDIO_BASE / source_rel

        if not source_path.exists():
            missing += 1
            print("MISSING:", source_path)
            continue

        # Short original sample: use FLAC directly.
        if original_duration <= 30.0:

            audio_ref = source_path

            original_used += 1

        else:

            # Long source: create only the required training clip.
            clip_path = CLIPS_ROOT / f'{x["id"]}.flac'

            if not clip_path.exists():

                # Write to a temporary FLAC first.
                # An interrupted ffmpeg run must never leave a final clip.
                tmp_clip = CLIPS_ROOT / f'{x["id"]}.tmp.flac'

                if tmp_clip.exists():
                    tmp_clip.unlink()

                start = float(x["audio_start"])
                duration = float(x["duration"])

                cmd = [
                    "ffmpeg",
                    "-hide_banner",
                    "-loglevel", "error",
                    "-y",
                    "-ss", str(start),
                    "-i", str(source_path),
                    "-t", str(duration),
                    "-vn",
                    "-c:a", "flac",
                    str(tmp_clip),
                ]

                subprocess.run(cmd, check=True)

                # Same filesystem: atomic promotion to final filename.
                tmp_clip.replace(clip_path)

                clips_created += 1

            audio_ref = clip_path

        rec = {
            "id": x["id"],
            "text": x["text"],
            "audio": str(audio_ref),
            "speaker": x["speaker"],
            "language": "sr",
            "duration": x["duration"]
        }

        fout.write(
            json.dumps(rec, ensure_ascii=False) + "\n"
        )

        written += 1
        hours += float(x["duration"])

        if written % 10000 == 0:
            print(
                f"{written:,} samples | "
                f"{hours / 3600:.1f} h | "
                f"clips created: {clips_created:,}"
            )

# Never publish a manifest from an incomplete source tree.
if missing != 0:
    if TMP_OUT.exists():
        TMP_OUT.unlink()

    raise RuntimeError(
        f"Dataset build incomplete: {missing} source audio files are missing."
    )

# The complete temporary manifest becomes canonical atomically.
TMP_OUT.replace(OUT)

print()
print("===================================")
print("DATASET READY")
print("===================================")

print("SAMPLES:", written)
print("HOURS:", round(hours / 3600, 3))
print("ORIGINAL FILES USED:", original_used)
print("CLIPS CREATED:", clips_created)
print("MISSING AUDIO:", missing)
print("MANIFEST:", OUT)
