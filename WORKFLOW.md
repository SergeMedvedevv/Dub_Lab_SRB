# DubLab SRB — Workflow

## Purpose

This document contains the **working and repeatable DubLab SRB production workflow**.

It is not a project journal.

It should contain only the steps that have already worked in practice and can be repeated on a new movie fragment.

The purpose of this file is simple:

> Open the workflow, choose a stage, follow the instructions, change the required paths or parameters, and reproduce the result.

Experimental history belongs in `JOURNAL.md`.

Future development belongs in `ROADMAP.md`.

---

## Current Working Pipeline

```text
Source Film
↓
Audio Preparation
↓
Dialogue / Background Separation
↓
Speech Recognition
↓
Alignment and Timestamps
↓
Speaker Diarization
↓
Character Mapping
↓
Dubbing Script CSV
↓
Serbian Translation
↓
Speech Generation
↓
Timeline Reconstruction
↓
Original Background Mix
↓
Dubbed Scene
```

---

# 1. Prepare the Source Material

## Purpose

Prepare a manageable movie fragment for processing.

For development and testing, do not start with a complete movie.

A short fragment makes it much easier to:

- detect errors;
- repeat processing;
- compare different models;
- regenerate individual lines;
- evaluate timing and dialogue quality.

## Recommended Length

```text
3–5 minutes
```

Shorter fragments can also be used for individual experiments.

## Input

A movie or video fragment containing the original dialogue and soundtrack.

Example:

```text
Eyes Wide Shut — test scene
```

## Recommended Project Folder

Create a separate folder for every movie or test scene.

Example:

```text
G:\DubLabSRB\VideoTest\My_New_Film\
```

Keep the source material and generated files inside the same project structure.

A simple example:

```text
My_New_Film\
│
├── source\
├── audio\
├── whisperx\
├── dubbing\
└── output\
```

The exact folder structure can be changed later.

The important rule is:

**do not mix files from different film tests.**

## Check

Before continuing, confirm that:

- the complete test scene is available;
- dialogue is clearly audible;
- the fragment begins and ends where expected;
- the file can be played normally.

---

# 2. Separate Dialogue from Music and Sound Effects

## Purpose

Create two separate audio tracks:

1. dialogue / voices;
2. background soundtrack without the main dialogue.

The dialogue track will be used for speech recognition and speaker analysis.

The background track will later be used to rebuild the dubbed soundtrack.

## Tool

**Ultimate Vocal Remover — UVR 5.6.0**

## Working Model

```text
UVR-MDX-NET Voc FT
```

This model produced a usable result on the Prototype V1 scene.

## Working Settings

```text
Process Method: MDX-Net
Model: UVR-MDX-NET Voc FT
Output Format: WAV
GPU Conversion: Enabled
Vocals Only: Disabled
Instrumental Only: Disabled
```

## Input

The original movie fragment or its original audio track.

For the first prototype, the movie material was processed directly through UVR.

## Output

UVR should create two WAV files.

Example:

```text
MyScene_(Vocals).wav
MyScene_(Instrumental).wav
```

Prototype V1 output:

```text
1_BigEyes_(Vocals).wav
1_BigEyes_(Instrumental).wav
```

### Vocals

Used for:

- WhisperX;
- diarization;
- dialogue analysis;
- speaker references;
- later expressive-speech experiments.

### Instrumental

Used later as the background for the Serbian dubbed soundtrack.

It should preserve as much as possible of:

- music;
- room ambience;
- traffic;
- environmental sounds;
- sound effects.

## Check

Listen to both files before continuing.

### Check `Vocals`

The file should contain clearly understandable dialogue.

Some residual background noise is acceptable.

### Check `Instrumental`

The original dialogue should be removed or strongly reduced.

Music and environmental sound should remain.

Do not continue if the original dialogue is still clearly understandable throughout the Instrumental track.

For the Eyes Wide Shut test scene, `UVR-MDX-NET Voc FT` produced a sufficiently clean result, so no additional separation model was required.

---

# 3. Activate the WhisperX Environment

## Purpose

WhisperX is used for:

- speech recognition;
- timestamps;
- alignment;
- structured transcript output;
- speaker diarization.

Use the existing dedicated Python environment rather than installing WhisperX into another project environment.

## Working Environment

```text
G:\DubLabSRB\whisperx_env
```

## Python Version Used

```text
Python 3.11.9
```

## Activate the Environment

Open Windows CMD.

Run:

```cmd
G:\DubLabSRB\whisperx_env\Scripts\activate
```

After activation, the command line should contain:

```text
(whisperx_env)
```

Example:

```text
(whisperx_env) C:\Users\YourName>
```

Keep this CMD window open while working with WhisperX.

---

# 4. Verify GPU / CUDA

## Purpose

Confirm that WhisperX will use the NVIDIA GPU instead of CPU processing.

This check should be performed before transcription if the environment or GPU configuration has changed.

## Command

```cmd
python -c "import torch; print('CUDA available:', torch.cuda.is_available()); print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NONE')"
```

## Expected Result on the DubLab PC

```text
CUDA available: True
GPU: NVIDIA GeForce RTX 2080
```

## If the Result Is False

Example:

```text
CUDA available: False
GPU: NONE
```

Do not continue with GPU transcription.

The PyTorch / CUDA installation must be corrected first.

## Check

The required result is:

```text
CUDA available: True
```

Once CUDA is confirmed, continue to WhisperX transcription.

# 5. Transcribe Dialogue with WhisperX

## Purpose

Convert the isolated dialogue track into:

- recognized text;
- segment timestamps;
- subtitle files;
- structured JSON data for later processing.

Use the `Vocals` file created by UVR.

Do not use the original mixed soundtrack if a clean Vocals track is already available.

---

## Input

Example:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).wav
```

---

## Basic Command Template

```cmd
whisperx "[VOCALS_FILE]" --model medium --language [LANGUAGE] --device cuda --compute_type float16 --output_dir "[OUTPUT_FOLDER]"
```

---

## What to Change

### `[VOCALS_FILE]`

Full path to the isolated dialogue WAV.

Example:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).wav
```

### `[LANGUAGE]`

Language of the original dialogue.

Common examples:

```text
en = English
sr = Serbian
hr = Croatian
ru = Russian
de = German
fr = French
it = Italian
es = Spanish
```

If the original language is known, specify it explicitly.

Example:

```text
--language en
```

This avoids unnecessary automatic language detection.

### `[OUTPUT_FOLDER]`

Folder where WhisperX should save the results.

Example:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR
```

---

## Working Prototype Command

```cmd
whisperx "G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).wav" --model medium --language en --device cuda --compute_type float16 --output_dir "G:\DubLabSRB\VideoTest\Eyes_Wide_UVR"
```

---

## Model

The working Prototype V1 used:

```text
medium
```

This provided a good balance between quality, speed and RTX 2080 VRAM usage.

---

## Device

Use:

```text
--device cuda
```

to run WhisperX on the NVIDIA GPU.

---

## Compute Type

Working setting:

```text
--compute_type float16
```

This reduces GPU memory usage and is suitable for the RTX 2080.

---

## Expected Output

WhisperX should generate several files, usually including:

```text
.json
.srt
.vtt
.tsv
.txt
```

The most important files are:

### `.json`

Used later for:

- structured dialogue data;
- timestamps;
- diarization;
- automatic CSV creation.

### `.srt`

Useful for quickly checking:

- recognized dialogue;
- subtitle timing;
- missing lines.

### `.tsv`

Useful for inspecting segment start and end times in a simple table.

---

## Example Result

A segment may look approximately like:

```text
24.327 → 25.708 | Tell me something.

31.171 → 38.357 | Those two girls at the party last night?
```

---

## Check the Result

Before moving to speaker diarization:

1. Open the generated `.srt` or `.txt`.
2. Check several dialogue lines against the movie.
3. Confirm that the text is generally correct.
4. Confirm that timestamps are approximately aligned with the spoken dialogue.
5. Check whether any obvious dialogue lines were completely missed.

Small recognition errors can be corrected later.

Very quiet speech may occasionally be missed and should be noted for manual correction.

---

## Result of This Stage

After this step, the project should contain:

```text
Vocals WAV
+
recognized dialogue
+
timestamps
+
WhisperX JSON
```

The next stage is:

**speaker diarization**

# 6. Add Speaker Diarization

## Purpose

Add speaker labels to the recognized dialogue.

After transcription, WhisperX already knows:

```text
what was said
when it was said
```

Diarization adds:

```text
who said it
```

This is required before dialogue can be mapped to characters such as:

```text
ALICE
BILL
```

---

## Requirements

You need:

- a Hugging Face account;
- a Hugging Face access token;
- access to the pyannote diarization model.

Working model:

```text
pyannote/speaker-diarization-community-1
```

Do not store your Hugging Face token in GitHub or public project files.

---

## Input

Use the same isolated dialogue file used for transcription.

Example:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).wav
```

---

## Command Template

```cmd
whisperx "[VOCALS_FILE]" --model medium --language [LANGUAGE] --device cuda --compute_type float16 --diarize --hf_token [HF_TOKEN] --min_speakers [MIN] --max_speakers [MAX] --output_dir "[OUTPUT_FOLDER]"
```

---

## What to Change

### `[VOCALS_FILE]`

Full path to the isolated dialogue WAV.

### `[LANGUAGE]`

Language of the original dialogue.

Example:

```text
en
```

### `[HF_TOKEN]`

Your private Hugging Face access token.

Example placeholder:

```text
YOUR_HF_TOKEN
```

### `[MIN]` and `[MAX]`

Expected number of speakers.

If the scene contains exactly two speakers:

```text
--min_speakers 2 --max_speakers 2
```

If the scene contains exactly three:

```text
--min_speakers 3 --max_speakers 3
```

If the exact number is not known, do not force an incorrect number.

---

## Working Prototype Command

For the Eyes Wide Shut test scene:

```cmd
whisperx "G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).wav" --model medium --language en --device cuda --compute_type float16 --diarize --hf_token YOUR_HF_TOKEN --min_speakers 2 --max_speakers 2 --output_dir "G:\DubLabSRB\VideoTest\Eyes_Wide_UVR"
```

---

## Expected Result

The generated JSON should now contain speaker labels such as:

```text
SPEAKER_00
SPEAKER_01
```

For the Prototype V1 scene, manual checking showed:

```text
SPEAKER_00 = BILL
SPEAKER_01 = ALICE
```

---

## Important

Speaker numbers are not character names.

Do not assume:

```text
SPEAKER_00 = first character
SPEAKER_01 = second character
```

The mapping must be checked manually from the actual dialogue.

---

## Possible Issue

Very short or very quiet lines may occasionally be labeled as:

```text
UNKNOWN
```

or may be missed completely.

This does not necessarily mean that the diarization pipeline failed.

Such lines can be corrected manually later.

---

## Check the Result

Open the resulting JSON, subtitle file, or a readable speaker list.

Check several lines where the speaker is obvious.

Confirm that:

- speaker changes occur in the correct places;
- the same character usually receives the same speaker ID;
- the total number of detected speakers looks reasonable.

---

## Result of This Stage

After this step, the transcript contains:

```text
start
end
text
speaker
```

The next stage is:

**map speaker IDs to character names and create a readable dialogue list**

# 7. Map Speaker IDs to Character Names

## Purpose

Convert technical diarization labels such as:

```text
SPEAKER_00
SPEAKER_01
```

into real character names such as:

```text
BILL
ALICE
```

This makes the transcript easier to read and prepares it for dubbing-script generation.

---

## Input

Use the diarized WhisperX output from the previous stage.

The transcript should already contain:

```text
start
end
text
speaker
```

Example speaker labels:

```text
SPEAKER_00
SPEAKER_01
```

---

## How to Identify the Characters

Manually check several lines where the speaker is obvious.

Compare the transcript with the movie scene.

For the Prototype V1 scene, the mapping was:

```text
SPEAKER_00 = BILL
SPEAKER_01 = ALICE
```

Do not assume that speaker numbering follows appearance order.

Always verify it manually.

---

## Speaker Mapping Example

The mapping can later be used in Python as:

```python
SPEAKER_MAP = {
    "SPEAKER_00": "BILL",
    "SPEAKER_01": "ALICE",
    "UNKNOWN": "UNKNOWN",
}
```

For another movie, replace the character names.

Example:

```python
SPEAKER_MAP = {
    "SPEAKER_00": "JOHN",
    "SPEAKER_01": "MARY",
    "SPEAKER_02": "DOCTOR",
    "UNKNOWN": "UNKNOWN",
}
```

---

## Important

Very short or unclear lines may sometimes be labeled:

```text
UNKNOWN
```

Do not force these lines to a character unless the speaker can be confirmed manually.

---

## Check

Before continuing, confirm that:

- each main speaker has a stable character name;
- speaker IDs are not accidentally reversed;
- uncertain lines remain marked separately;
- the mapping matches the actual movie dialogue.

---

## Result of This Stage

You should now have a confirmed speaker map such as:

```text
SPEAKER_00 → BILL
SPEAKER_01 → ALICE
```

The next stage is:

**create a readable dialogue list for manual checking**

# 8. Create a Readable Dialogue List

## Purpose

Create a simple text version of the diarized transcript that is easy to inspect manually.

The WhisperX JSON contains the information we need, but it is inconvenient to read directly.

This step creates a file in the format:

```text
start → end | speaker | dialogue
```

This makes it easier to check:

- timestamps;
- speaker changes;
- missed lines;
- obvious recognition errors.

---

## Input

Use the diarized WhisperX JSON from the previous stage.

Prototype example:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).json
```

---

## Working Command

```cmd
python -c "import json; p=r'G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).json'; d=json.load(open(p,encoding='utf-8')); f=open(r'G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\dialogue_speakers.txt','w',encoding='utf-8'); [f.write(f'{s.get(\"start\",0):08.3f} -> {s.get(\"end\",0):08.3f} | {s.get(\"speaker\",\"UNKNOWN\")} | {s.get(\"text\",\"\").strip()}\n') for s in d['segments']]; f.close()"
```

---

## What to Change

Change the input JSON path:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).json
```

to the JSON file of the new project.

Also change the output path if needed:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\dialogue_speakers.txt
```

---

## Expected Output

A new file:

```text
dialogue_speakers.txt
```

Example content:

```text
0024.327 -> 0025.708 | SPEAKER_01 | Tell me something.
0031.171 -> 0038.357 | SPEAKER_01 | Those two girls at the party last night?
0060.188 -> 0060.448 | SPEAKER_00 | What?
```

---

## Check

Open `dialogue_speakers.txt` and compare several lines with the movie.

Check:

- whether timestamps appear in the correct order;
- whether the expected speaker ID changes at the right moments;
- whether any obvious dialogue is missing;
- whether there are clear transcription errors;
- whether `UNKNOWN` lines need manual attention.

This is a convenient manual verification step before creating the dubbing CSV.

---

## Result of This Stage

You now have a human-readable dialogue list containing:

```text
timestamp
speaker
dialogue
```

The next stage is:

**create the structured dubbing CSV**

# 9. Create the Dubbing CSV

## Purpose

Convert the diarized WhisperX transcript into a structured dubbing table that can be used for translation, TTS generation and later timeline reconstruction.

The CSV should contain:

```text
start | end | character | english | serbian
```

The first four columns come from the recognized dialogue.

The `serbian` column is initially left empty and will be filled during translation.

---

## Input

Use the diarized WhisperX JSON from the previous stages.

Prototype example:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).json
```

Before running this step, the speaker mapping should already be known.

Prototype mapping:

```text
SPEAKER_00 = BILL
SPEAKER_01 = ALICE
```

---

## Working Command

```cmd
python -c "import json,csv; p=r'G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).json'; out=r'G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\dubbing_script.csv'; d=json.load(open(p,encoding='utf-8')); m={'SPEAKER_00':'BILL','SPEAKER_01':'ALICE','UNKNOWN':'UNKNOWN'}; f=open(out,'w',newline='',encoding='utf-8-sig'); w=csv.writer(f); w.writerow(['start','end','character','english','serbian']); [w.writerow([f'{s.get(\"start\",0):.3f}',f'{s.get(\"end\",0):.3f}',m.get(s.get('speaker','UNKNOWN'),s.get('speaker','UNKNOWN')),s.get('text','').strip(),'']) for s in d['segments']]; f.close()"
```

---

## What to Change

### Input JSON

Change:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Vocals).json
```

to the JSON file of the new project.

### Output CSV

Change:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\dubbing_script.csv
```

if another output folder or filename is required.

### Speaker Mapping

Prototype mapping:

```python
{
    "SPEAKER_00": "BILL",
    "SPEAKER_01": "ALICE",
    "UNKNOWN": "UNKNOWN"
}
```

For another scene, replace the names.

Example:

```python
{
    "SPEAKER_00": "JOHN",
    "SPEAKER_01": "MARY",
    "SPEAKER_02": "DOCTOR",
    "UNKNOWN": "UNKNOWN"
}
```

Do not reuse the BILL / ALICE mapping for another movie without checking the diarization first.

---

## Expected Output

The command creates:

```text
dubbing_script.csv
```

The structure should look like:

```text
start,end,character,english,serbian
24.327,25.708,ALICE,Tell me something.,
31.171,38.357,ALICE,Those two girls at the party last night?,
60.188,60.448,BILL,What?,
```

---

## Column Meaning

### `start`

Beginning of the original dialogue segment in seconds.

Example:

```text
31.171
```

### `end`

End of the original dialogue segment in seconds.

Example:

```text
38.357
```

### `character`

Character name created from the speaker mapping.

Example:

```text
ALICE
```

### `english`

Original recognized dialogue.

Example:

```text
Those two girls at the party last night?
```

### `serbian`

Target Serbian dialogue.

At this stage it should still be empty.

---

## Check

Open `dubbing_script.csv`.

Confirm that:

- the file opens correctly;
- timestamps are present;
- character names are correct;
- English dialogue is present;
- Serbian cells are empty;
- no columns were shifted or corrupted.

Pay special attention to:

```text
UNKNOWN
```

lines.

If the speaker can be identified manually, correct the character name before translation.

---

## Result of This Stage

You now have the main working dubbing table:

```text
start
end
character
english
serbian
```

This file becomes the central data structure for the next stages.

The next stage is:

**translate the dialogue into Serbian**

# 10. Translate the Dialogue into Serbian

## Purpose

Fill the `serbian` column in the dubbing CSV while preserving the technical structure of the file.

The goal is not only to translate the meaning correctly, but also to prepare dialogue that can later be spoken naturally.

---

## Input

Use:

```text
dubbing_script.csv
```

The file should already contain:

```text
start
end
character
english
serbian
```

At this stage, the `serbian` column should still be empty.

---

## What Must Not Be Changed

Do not modify:

```text
start
end
character
english
```

These columns are required later for:

- timing;
- character voice assignment;
- dialogue generation;
- timeline reconstruction.

Only fill:

```text
serbian
```

---

## Translation Goal

The Serbian version should sound like spoken dialogue, not like a literal written translation.

Important priorities:

- preserve the original meaning;
- preserve the emotional tone;
- preserve the character's way of speaking;
- keep profanity or strong language when it is important to the scene;
- avoid unnecessarily long phrases;
- keep short lines short where possible;
- prefer natural spoken Serbian over overly formal wording.

---

## Duration Consideration

The original dialogue duration is available from:

```text
end - start
```

This can be used as a rough guide.

Example:

```text
start = 31.171
end   = 38.357
```

Approximate available window:

```text
7.186 seconds
```

Do not force the Serbian translation to exactly match this duration at the translation stage.

The original actor may include:

- pauses;
- hesitation;
- stretched words;
- silence;
- slow emotional delivery.

However, avoid making the Serbian version unnecessarily longer than the original.

---

## Example

Original:

```text
Those two girls at the party last night?
```

Possible Serbian dubbing version:

```text
One dve devojke sa sinoćne zabave?
```

The translation should preserve the conversational character of the original line.

---

## Recommended Workflow

Translate the dialogue in batches rather than line by line manually.

After translation:

1. preserve all original rows;
2. preserve timestamps;
3. preserve character names;
4. preserve original English text;
5. fill only the Serbian column.

---

## Expected Output

Save the translated version as a new file.

Prototype example:

```text
dubbing_script_SR.csv
```

Do not overwrite the original untranslated CSV unless there is a specific reason to do so.

Recommended structure:

```text
dubbing_script.csv
dubbing_script_SR.csv
```

This keeps both versions available.

---

## Example Output

```text
start,end,character,english,serbian
24.327,25.708,ALICE,Tell me something.,Reci mi nešto.
31.171,38.357,ALICE,Those two girls at the party last night?,One dve devojke sa sinoćne zabave?
60.188,60.448,BILL,What?,Šta?
```

---

## Check

Before continuing, verify that:

- every row still exists;
- timestamps were not changed;
- character names were not changed;
- English dialogue is still present;
- Serbian text is in the correct row;
- the Serbian text sounds natural when read aloud;
- no CSV columns were accidentally shifted.

Pay additional attention to:

```text
UNKNOWN
```

speaker lines.

If possible, identify and correct the character before generating speech.

---

## Result of This Stage

You now have a complete dubbing script containing:

```text
timing
character
original dialogue
Serbian translation
```

This becomes the input for speech generation.

The next stage is:

**generate Serbian dialogue with TTS**

# 11. Generate Serbian Dialogue with TTS

## Purpose

Generate one Serbian audio file for each dialogue line while preserving the character assignment from the dubbing CSV.

At this stage, the goal is not perfect expressive dubbing.

The goal is to create a repeatable baseline:

```text
CSV
↓
character
↓
Serbian text
↓
voice selection
↓
generated audio
```

---

## Input

Use the translated dubbing file:

```text
dubbing_script_SR.csv
```

The file should contain:

```text
start
end
character
english
serbian
```

Example:

```text
24.327,25.708,ALICE,Tell me something.,Reci mi nešto.
31.171,38.357,ALICE,Those two girls at the party last night?,One dve devojke sa sinoćne zabave?
60.188,60.448,BILL,What?,Šta?
```

---

## Working Environment

Prototype V1 used the existing WhisperX environment:

```text
G:\DubLabSRB\whisperx_env
```

Activate it:

```cmd
G:\DubLabSRB\whisperx_env\Scripts\activate
```

Expected prompt:

```text
(whisperx_env)
```

---

## TTS Engine Used in Prototype V1

The working Prototype V1 used:

**ElevenLabs Text-to-Speech API**

This stage can later be replaced by another TTS engine while keeping the same CSV structure and character-selection logic.

---

## API Key

The ElevenLabs API key was stored as a Windows environment variable:

```text
ELEVENLABS_API_KEY
```

Do not write private API keys directly into Python scripts.

Do not upload API keys to GitHub.

To check whether the key is available in the current CMD session:

```cmd
echo %ELEVENLABS_API_KEY%
```

If the variable is configured correctly, the key should be returned.

---

## Character Voice Mapping

Each character must be assigned a Voice ID.

Prototype structure:

```python
VOICE_IDS = {
    "ALICE": "VOICE_ID_ALICE",
    "BILL": "VOICE_ID_BILL",
}
```

The important part is that the script uses the `character` column from the CSV to select the correct voice automatically.

For another scene, add or replace characters as needed.

Example:

```python
VOICE_IDS = {
    "JOHN": "VOICE_ID_JOHN",
    "MARY": "VOICE_ID_MARY",
    "DOCTOR": "VOICE_ID_DOCTOR",
}
```

---

## Important ElevenLabs Note

During Prototype V1, selected Voice Library voices could not be used through the Free API plan.

Default voices available to the account worked through the API.

This restriction may change in the future.

If the API returns a payment or voice-access error, verify that the selected Voice ID is available for API use on the current account.

---

## Working Script

Prototype script:

```text
generate_test.py
```

The script reads:

```text
dubbing_script_SR.csv
```

and automatically performs:

```text
read row
↓
read character
↓
read Serbian text
↓
select Voice ID
↓
generate speech
↓
save audio file
```

---

## Recommended File Naming

Generated dialogue files should contain enough information to identify:

- line number;
- original start timestamp;
- character.

Prototype naming style:

```text
001_24.327_ALICE.mp3
002_31.171_ALICE.mp3
003_60.188_BILL.mp3
```

This makes later timeline reconstruction much easier.

---

## Recommended First Test

Do not generate the complete scene immediately.

Start with approximately:

```text
10 dialogue lines
```

This is enough to check:

- API access;
- Serbian pronunciation;
- character switching;
- Voice IDs;
- file naming;
- generation errors.

Only continue to the full scene after the small test works correctly.

---

## Expected Output

A folder containing separate generated dialogue files.

Example:

```text
TTS_TEST\
│
├── 001_24.327_ALICE.mp3
├── 002_31.171_ALICE.mp3
├── 003_60.188_BILL.mp3
└── ...
```

---

## Check

Listen to several generated files individually.

Confirm that:

- Serbian text is spoken correctly;
- the correct character voice is used;
- no line is empty;
- no line is truncated;
- filenames correspond to the correct dialogue rows.

Also compare short and long lines.

Normal TTS may pronounce long dialogue significantly faster than the original actor.

This is a known V1 limitation and will be analyzed later.

---

## Result of This Stage

You now have separate Serbian dialogue audio files assigned to the correct characters.

The next stage is:

**place the generated dialogue back onto the original movie timeline**

# 12. Reconstruct the Dialogue Timeline

## Purpose

Place every generated Serbian dialogue line back at its original position in the movie.

The original WhisperX timestamps are used to determine where each generated line should begin.

The background soundtrack created by UVR is used as the base audio track.

---

## Input

You need:

- the original `Instrumental` WAV;
- the generated Serbian dialogue files;
- the original start timestamps.

Prototype background file:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\1_BigEyes_(Instrumental).wav
```

Prototype generated dialogue folder:

```text
G:\DubLabSRB\VideoTest\Eyes_Wide_UVR\TTS_TEST
```

Example generated files:

```text
001_24.327_ALICE.mp3
002_31.171_ALICE.mp3
003_60.188_BILL.mp3
```

The timestamp inside the filename represents the original line start time.

---

## Required Python Package

The Prototype V1 timeline script used:

```text
pydub
```

Install it inside the active Python environment if needed:

```cmd
pip install pydub
```

---

## Working Prototype Script

Prototype script:

```text
mix_test.py
```

Example working code:

```python
from pathlib import Path
from pydub import AudioSegment
import re

BASE_DIR = Path(r"G:\DubLabSRB\VideoTest\Eyes_Wide_UVR")
TTS_DIR = BASE_DIR / "TTS_TEST"

INSTRUMENTAL = BASE_DIR / "1_BigEyes_(Instrumental).wav"
OUTPUT = BASE_DIR / "Eyes_Wide_V1_TEST.wav"

print("Loading background...")
background = AudioSegment.from_wav(INSTRUMENTAL)

files = sorted(TTS_DIR.glob("*.mp3"))

print(f"Dialogue files found: {len(files)}")

for file in files:

    match = re.match(
        r"\d+_([0-9.]+)_(ALICE|BILL)\.mp3",
        file.name
    )

    if not match:
        print(f"Skipping: {file.name}")
        continue

    start_seconds = float(match.group(1))
    start_ms = int(start_seconds * 1000)

    voice = AudioSegment.from_mp3(file)

    print(
        f"{file.name} | "
        f"start {start_seconds:.3f}s | "
        f"length {len(voice)/1000:.2f}s"
    )

    background = background.overlay(
        voice,
        position=start_ms
    )

print("Saving...")

background.export(
    OUTPUT,
    format="wav"
)

print()
print("DONE")
print(OUTPUT)
```

---

## What to Change

### Base Project Folder

Change:

```python
BASE_DIR = Path(r"G:\DubLabSRB\VideoTest\Eyes_Wide_UVR")
```

to the folder of the new project.

### Generated Dialogue Folder

Change if needed:

```python
TTS_DIR = BASE_DIR / "TTS_TEST"
```

### Instrumental Filename

Change:

```python
INSTRUMENTAL = BASE_DIR / "1_BigEyes_(Instrumental).wav"
```

to the new background-track filename.

### Character Names

This part:

```python
(ALICE|BILL)
```

must match the characters used in the generated filenames.

Example for three characters:

```python
(JOHN|MARY|DOCTOR)
```

---

## Run the Script

Example:

```cmd
python G:\DubLabSRB\VideoTest\mix_test.py
```

Use the actual script path if it is stored elsewhere.

---

## Expected Output

Prototype output:

```text
Eyes_Wide_V1_TEST.wav
```

This WAV contains:

```text
original music / ambience / sound effects
+
generated Serbian dialogue
```

The dialogue should already be positioned according to the original timestamps.

---

## Test with the Original Video

Open the movie fragment in a video editor.

1. Place the original video on the timeline.
2. Mute the original video audio.
3. Place the generated WAV under the video.
4. Align the generated WAV to:

```text
00:00
```

Do not manually move individual dialogue lines during the first check.

The purpose of this test is to verify the automatic timeline reconstruction.

---

## Check

Watch the test scene and verify:

- whether each dialogue line begins at the correct moment;
- whether ALICE and BILL use the correct voices;
- whether any dialogue line is missing;
- whether two generated lines overlap incorrectly;
- whether the background soundtrack remains natural;
- whether generated speech ends too early or too late compared with the actor.

In Prototype V1, the line start positions were accurate.

The main problem was not placement.

The main problem was **generated dialogue duration**.

Long TTS lines often finished significantly earlier than the original acting performance.

---

## Important

Do not correct every line manually before evaluating the automatic result.

First determine whether the problem comes from:

```text
wrong start timestamp
```

or:

```text
wrong generated duration
```

These are different problems and should be handled separately.

---

## Result of This Stage

You now have the first automatically reconstructed Serbian soundtrack:

```text
Instrumental
+
generated dialogue
+
original timing
```

The next stage is:

**measure generated dialogue duration and identify lines that do not match the original performance window**

# 13. Analyze Generated Dialogue Duration

## Purpose

Measure how closely the generated Serbian dialogue matches the original dialogue duration.

This step helps identify lines that:

- finish too early;
- run too long;
- may need regeneration;
- may be suitable for small time-stretch correction.

---

## Input

You need:

- `dubbing_script_SR.csv`
- generated dialogue files from the TTS stage

Prototype examples:

```text
dubbing_script_SR.csv
```

and:

```text
TTS_TEST\
```

---

## Duration Reference

The original available dialogue window is calculated as:

```text
target duration = end - start
```

Example:

```text
start = 99.801
end   = 104.184
```

Target duration:

```text
4.383 seconds
```

The generated TTS file may have a different duration.

Example:

```text
2.461 seconds
```

---

## Working Prototype Script

Prototype script:

```text
check_duration.py
```

Example working code:

```python
import csv
from pathlib import Path
from pydub import AudioSegment

BASE_DIR = Path(r"G:\DubLabSRB\VideoTest\Eyes_Wide_UVR")

CSV_FILE = BASE_DIR / "dubbing_script_SR.csv"
TTS_DIR = BASE_DIR / "TTS_TEST"

TEST_LIMIT = 10

with open(CSV_FILE, "r", encoding="utf-8-sig", newline="") as f:
    rows = list(csv.DictReader(f))

print()
print("DURATION CHECK")
print("-" * 80)

checked = 0

for index, row in enumerate(rows, start=1):

    if checked >= TEST_LIMIT:
        break

    character = row["character"].strip().upper()

    if character not in ("ALICE", "BILL"):
        continue

    start = float(row["start"])
    end = float(row["end"])
    target_duration = end - start

    pattern = f"{index:03d}_{row['start']}_{character}.mp3"
    audio_file = TTS_DIR / pattern

    if not audio_file.exists():
        print(f"{index:03d} {character} | FILE NOT FOUND | {audio_file.name}")
        continue

    audio = AudioSegment.from_mp3(audio_file)
    generated_duration = len(audio) / 1000

    ratio = (
        target_duration / generated_duration
        if generated_duration > 0
        else 0
    )

    difference = target_duration - generated_duration

    print(
        f"{index:03d} {character:5} | "
        f"target {target_duration:6.3f}s | "
        f"generated {generated_duration:6.3f}s | "
        f"diff {difference:+6.3f}s | "
        f"ratio {ratio:5.2f}"
    )

    checked += 1

print("-" * 80)
print("DONE")
```

---

## What to Change

### Project Folder

Change:

```python
BASE_DIR = Path(r"G:\DubLabSRB\VideoTest\Eyes_Wide_UVR")
```

to the folder of the new project.

### CSV Filename

Change if required:

```python
CSV_FILE = BASE_DIR / "dubbing_script_SR.csv"
```

### Generated Dialogue Folder

Change if required:

```python
TTS_DIR = BASE_DIR / "TTS_TEST"
```

### Character Names

This line:

```python
if character not in ("ALICE", "BILL"):
```

must match the characters used in the current project.

Example:

```python
if character not in ("JOHN", "MARY", "DOCTOR"):
```

### Number of Lines to Test

For a small first test:

```python
TEST_LIMIT = 10
```

Increase the value when analyzing more dialogue.

---

## Run the Script

Example:

```cmd
python G:\DubLabSRB\VideoTest\check_duration.py
```

Use the actual script path if it is stored elsewhere.

---

## Example Output

```text
001 ALICE | target 1.381s | generated 1.068s | diff +0.313s | ratio 1.29
002 ALICE | target 7.186s | generated 2.090s | diff +5.096s | ratio 3.44
004 ALICE | target 8.671s | generated 1.904s | diff +6.767s | ratio 4.55
010 ALICE | target 4.383s | generated 2.461s | diff +1.922s | ratio 1.78
```

---

## How to Read the Result

### `target`

Original dialogue window:

```text
end - start
```

### `generated`

Real duration of the generated TTS audio.

### `diff`

Difference between the original window and generated speech.

Positive value:

```text
generated speech is shorter
```

Negative value:

```text
generated speech is longer
```

### `ratio`

Approximate stretch factor required to fill the original window.

Example:

```text
ratio 1.29
```

means the generated line would need to become approximately 1.29 times longer.

---

## Important Limitation

Do not assume that every line should be stretched exactly to:

```text
end - start
```

The original segment may contain:

- pauses;
- hesitation;
- breathing;
- stretched words;
- silence;
- slow emotional delivery.

Example:

A segment may have an 8-second window even though the actor is not speaking continuously for all 8 seconds.

Therefore, the duration report is a diagnostic tool.

It is not an automatic lip-sync target for every line.

---

## Practical Interpretation

### Small Difference

Example:

```text
ratio 1.10–1.30
```

A small correction may be acceptable.

### Medium Difference

Example:

```text
ratio 1.30–1.50
```

Test carefully.

The result may still sound natural depending on the dialogue.

### Large Difference

Example:

```text
ratio 1.70+
```

Do not automatically stretch the audio.

Large corrections can create audible artifacts.

The better solution may be:

- regenerate the line;
- change pacing during synthesis;
- use expressive duration control;
- adjust the translation;
- preserve pauses during generation.

---

## Prototype Observation

Short lines usually matched the original scene much better.

Longer lines showed much larger duration differences.

This confirmed that the main V1 problem was not timestamp placement.

It was the way normal TTS compressed longer dialogue into a faster delivery.

---

## Result of This Stage

You now know which lines:

- already fit reasonably well;
- need a small timing correction;
- require a different generation strategy.

The next optional stage is:

**small time-stretch correction for lines with minor duration mismatch**

# 14. Small Time-Stretch Correction

## Purpose

Apply a small duration correction to generated dialogue when the line is only slightly shorter than the original dialogue window.

This is an optional V1 correction step.

It should not be used as the main solution for large timing differences.

---

## When to Use It

Time-stretch can be useful when the generated line is already close to the required duration.

Example:

```text
target duration:    1.381 s
generated duration: 1.068 s
ratio:              1.29
```

A correction around this range may still sound natural.

---

## When Not to Use It

Avoid strong stretching when the required correction is large.

Example:

```text
target duration:    4.383 s
generated duration: 2.461 s
ratio:              1.78
```

In Prototype V1, a correction around `×1.78` improved timing but introduced audible artifacts.

The voice began to sound unstable and slightly unnatural.

Large corrections should preferably be solved during speech generation.

---

## Tool

The working prototype used:

```text
FFmpeg
```

with the:

```text
atempo
```

audio filter.

`atempo` changes speech speed while trying to preserve pitch.

---

## Important

FFmpeg `atempo` works with speed rather than final duration.

If the required stretch ratio is:

```text
1.29
```

the tempo value is approximately:

```text
1 / 1.29 = 0.775
```

A tempo value below `1.0` makes the audio longer.

---

## Working Prototype Script

Prototype script:

```text
stretch_test.py
```

Example:

```python
import subprocess
from pathlib import Path

BASE_DIR = Path(r"G:\DubLabSRB\VideoTest\Eyes_Wide_UVR")

TTS_DIR = BASE_DIR / "TTS_TEST"
OUT_DIR = BASE_DIR / "TTS_STRETCH_TEST"

OUT_DIR.mkdir(exist_ok=True)

tests = [
    ("001_24.327_ALICE.mp3", 1.29),
    ("010_99.801_ALICE.mp3", 1.78),
]

for filename, stretch_ratio in tests:

    src = TTS_DIR / filename

    if not src.exists():
        print(f"File not found: {src}")
        continue

    tempo = 1 / stretch_ratio

    out = OUT_DIR / filename.replace(
        ".mp3",
        f"_stretch_{stretch_ratio:.2f}.wav"
    )

    print()
    print(f"File: {filename}")
    print(f"Stretch ratio: {stretch_ratio:.2f}")
    print(f"FFmpeg atempo: {tempo:.3f}")

    subprocess.run([
        "ffmpeg",
        "-y",
        "-i", str(src),
        "-filter:a", f"atempo={tempo:.6f}",
        str(out)
    ], check=True)

    print(f"Created: {out.name}")

print()
print("DONE")
```

---

## What to Change

### Project Folder

Change:

```python
BASE_DIR = Path(r"G:\DubLabSRB\VideoTest\Eyes_Wide_UVR")
```

to the current project folder.

### Input Dialogue Folder

Change if needed:

```python
TTS_DIR = BASE_DIR / "TTS_TEST"
```

### Output Folder

The corrected versions are saved separately:

```python
OUT_DIR = BASE_DIR / "TTS_STRETCH_TEST"
```

Keeping stretched files separate prevents the original TTS files from being overwritten.

### Test Lines

Edit:

```python
tests = [
    ("001_24.327_ALICE.mp3", 1.29),
]
```

Use the filename and ratio found during the duration-analysis stage.

---

## Run the Script

Example:

```cmd
python G:\DubLabSRB\VideoTest\stretch_test.py
```

Use the actual location of the script.

---

## Expected Output

Example:

```text
TTS_STRETCH_TEST\
│
├── 001_24.327_ALICE_stretch_1.29.wav
└── 010_99.801_ALICE_stretch_1.78.wav
```

The original generated files remain unchanged.

---

## Check

Always listen to the corrected file before adding it to the movie timeline.

Compare:

```text
original TTS
vs
stretched TTS
```

Check for:

- unstable voice tone;
- metallic artifacts;
- unnatural vowels;
- doubled or phase-like voice character;
- overly slow speech.

Then check the corrected line inside the movie scene.

A line that sounds slightly slow by itself may fit much better when viewed together with the actor.

---

## Prototype Result

### Ratio ×1.29

Result:

```text
good
```

The line remained natural and matched the timing more closely.

### Ratio ×1.78

Result:

```text
timing improved
audio quality degraded
```

The line matched the actor duration much better, but noticeable artifacts appeared.

---

## Practical Rule

Use time-stretch mainly for small corrections.

A practical starting guideline:

```text
1.00–1.30 → usually worth testing

1.30–1.50 → use carefully

1.50+ → prefer regeneration or expressive duration control
```

These values are not strict technical limits.

Always judge the final result by listening and watching the scene.

---

## Result of This Stage

Small timing mismatches can now be corrected without changing the original TTS files.

Large mismatches should be passed to a better speech-generation method rather than aggressively stretched.

The next stage is:

**final validation of the reconstructed V1 scene**

# 15. Final Validation of the V1 Scene

## Purpose

Evaluate the reconstructed Serbian soundtrack inside the real movie scene.

This step is used to identify whether remaining problems come from:

- transcription;
- speaker assignment;
- translation;
- TTS generation;
- dialogue duration;
- timeline placement;
- background mixing.

---

## Input

You need:

- the original movie fragment;
- the reconstructed Serbian WAV;
- a video editor.

Prototype output:

```text
Eyes_Wide_V1_TEST.wav
```

---

## Setup

Place the original video on the editor timeline.

Mute the original movie audio.

Add the generated Serbian WAV underneath the video.

Align both tracks to:

```text
00:00
```

Do not manually shift the complete generated track unless there is a confirmed global timing error.

---

## Check the Scene from the Beginning

Watch the complete test fragment without stopping after every line.

The first pass should answer:

> Does the scene work as a whole?

Check the general impression before correcting individual details.

---

## Check Dialogue Start Timing

Each generated line should begin approximately where the original actor begins speaking.

If the start timing is wrong, check:

- WhisperX timestamps;
- generated filename timestamp;
- timeline reconstruction script.

Do not confuse start-time problems with duration problems.

A line can begin correctly but still finish too early.

---

## Check Character Voices

Confirm that:

```text
ALICE → ALICE voice
BILL  → BILL voice
```

Check all speaker changes.

If the wrong voice appears, verify:

- character mapping;
- CSV character value;
- Voice ID mapping;
- generated filename.

---

## Check Missing Dialogue

Listen for any original lines that do not have a Serbian replacement.

Possible causes:

- WhisperX missed the line;
- diarization did not assign it;
- the CSV line is missing;
- TTS generation failed;
- the audio file was not included in the mix.

Very quiet speech may require manual correction.

Prototype V1 contained one quiet BILL line that WhisperX did not recognize.

---

## Check Dialogue Duration

Pay special attention to longer lines.

Typical V1 problem:

```text
line starts correctly
↓
Serbian TTS speaks too quickly
↓
generated voice ends
↓
actor continues speaking
```

If the mismatch is small, test a minor time-stretch correction.

If the mismatch is large, mark the line for regeneration or expressive speech generation.

---

## Check Overlapping Dialogue

Confirm that generated lines do not overlap incorrectly.

Some overlap may be correct if the original actors speak over each other.

Do not automatically remove overlap without checking the original scene.

---

## Check the Background Soundtrack

The reconstructed background should still feel like the original movie.

Listen for:

- missing ambience;
- damaged music;
- sudden changes in noise;
- remaining original dialogue;
- unnatural volume changes.

The purpose of dubbing is to replace speech without destroying the original sound environment.

---

## Check Voice Level

Generated dialogue should be clearly audible but should not feel disconnected from the movie.

Avoid:

- dialogue that is much louder than the scene;
- dialogue that is buried under the background;
- major volume differences between characters.

Detailed mastering can be done later.

At the prototype stage, the goal is consistent and understandable dialogue.

---

## Make a Problem List

Do not immediately edit every problem while watching.

Create a short list.

Example:

```text
Line 10 — too short
Line 17 — wrong speaker
Line 26 — pronunciation issue
Line 43 — missing quiet dialogue
Line 51 — voice too loud
```

Then correct problems by category.

This makes debugging much faster than changing the timeline randomly.

---

## Final V1 Evaluation

Evaluate the scene using:

```text
Transcription
Speaker accuracy
Translation
Pronunciation
Start timing
Dialogue duration
Voice consistency
Background quality
Overall watchability
```

The most important final question is:

> Can the scene be watched naturally without the dubbing constantly distracting from the movie?

---

## Prototype V1 Result

The first V1 scene confirmed that:

- automatic timestamp placement works;
- speaker-based voice assignment works;
- Serbian dialogue can be generated automatically;
- the original background can be reused;
- the reconstructed soundtrack can be watched with the original video.

The main remaining quality problem was:

```text
long dialogue pacing / duration
```

This led to the expressive V2 research.

---

## Result of This Stage

At this point, the complete V1 workflow has been tested from:

```text
source film
```

to:

```text
watchable Serbian-dubbed scene
```

Remaining quality problems should now be documented and passed to the appropriate improvement stage rather than changing the stable pipeline itself.

# 16. Current V1 Status and Transition to V2

## What V1 Already Solves

The current V1 workflow is able to process a real movie fragment from beginning to end.

The stable pipeline can already:

```text
separate dialogue from background
↓
recognize speech
↓
generate timestamps
↓
identify speakers
↓
map speakers to characters
↓
create a structured dubbing CSV
↓
translate dialogue into Serbian
↓
generate Serbian TTS
↓
place dialogue on the original timeline
↓
rebuild the soundtrack
↓
produce a watchable dubbed scene
```

This means the basic production chain is already proven.

---

## What V1 Does Not Solve Well

The main limitations are related to performance rather than pipeline structure.

Normal TTS does not reliably preserve:

- original speech rate;
- internal pauses;
- stretched words;
- emotional rhythm;
- whisper / quiet delivery;
- acting intensity;
- original dialogue duration.

These problems are especially visible in longer dialogue lines.

---

## Why V2 Is Needed

The goal of V2 is not to replace the complete V1 pipeline.

Most of V1 remains useful.

The main change happens at the speech-generation stage.

Instead of:

```text
Serbian text
↓
normal TTS
↓
generated speech
```

V2 aims for:

```text
Serbian text
+
original performance information
↓
expressive speech generation
↓
speech closer to the original acting performance
```

---

## V2 Target

The ideal V2 result should preserve as much as reasonably possible of:

```text
speaker identity
emotion
speech rate
pauses
quiet / loud delivery
approximate duration
overall performance shape
```

Perfect reproduction is not required.

The goal is:

> The translated line should feel like the same scene and approximately the same performance, but in Serbian.

---

## V2 Research Status

Several systems have already been investigated.

Commercial benchmark:

```text
ElevenLabs Dubbing
```

Most promising local experimental direction:

```text
TED-TTS / IndexTTS-2
```

The strongest local test so far combined:

```text
speaker reference
+
emotion control
+
target duration
```

This produced a significantly better result than normal TTS.

---

## Current V2 Limitation

The current IndexTTS-2 model does not support natural Serbian pronunciation.

Therefore the main research problem is currently:

```text
Serbian language support
```

rather than:

```text
voice cloning
emotion control
duration control
```

---

## Important Workflow Rule

Do not replace the stable V1 workflow with experimental V2 components until they are reliable enough to repeat.

Experimental work belongs in:

```text
JOURNAL.md
```

and research notes.

Once a V2 step becomes stable and reproducible, it can be added to this Workflow as a new production stage.

---

# Workflow Status

## V1

```text
STABLE / REPEATABLE
```

## V2

```text
EXPERIMENTAL
```

## Serbian Expressive Speech

```text
IN DEVELOPMENT
```

---

# Principle

Keep the production workflow stable.

Improve one component at a time.

Do not automate an unstable stage.

Do not replace a working step until the new step has clearly proven better.

**First prove the quality. Then make it reproducible. Then automate it.**

