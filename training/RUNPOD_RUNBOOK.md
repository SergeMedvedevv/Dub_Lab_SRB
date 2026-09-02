# DubLab SRB — RunPod Runbook

## 0. Server requirements

Recommended first GPU:
- NVIDIA A40 48 GB

Workspace:
- preferably 200–250+ GB
- project root: /workspace/DubLabSRB

Upload the entire Server_Package folder to:

/workspace/DubLabSRB/Server_Package


## 1. Install and prepare environment

cd /workspace/DubLabSRB/Server_Package

chmod +x *.sh

bash RUNPOD_SETUP.sh

Expected:
- GPU detected
- trainer installed
- IndexTTS-2 checkpoints downloaded
- Serbian tokenizer/config/GPT copied into trainer checkpoints


## 2. Preflight

bash SERVER_PREFLIGHT.sh

Expected final line:

PREFLIGHT SUCCESS

Do not continue if preflight fails.


## 3. Download full ParlaSpeech-RS

bash PREPARE_PARLASPEECH.sh

Expected:
- both archives downloaded
- MD5 verified
- archives extracted
- archives deleted after extraction
- FLAC files found


## 4. Build final Serbian audio dataset

python3 BUILD_DATASET.py

Uses:
- parlaspeech_sr_split_plan_v3.jsonl
- original short FLAC directly
- creates clips only for long recordings

Expected approximately:
- 304450 samples
- ~896.219 hours
- MISSING AUDIO: 0


## 5. End-to-end smoke test

bash SMOKE_TEST.sh

This performs:
- preprocessing of 50 samples
- GPT prompt/target pair generation
- 20 real training optimizer steps
- checkpoint save

Required final result:

SMOKE TEST SUCCESS

Do NOT launch full preprocessing before this succeeds.


## 6. Full preprocessing

bash RUN_PREPROCESS.sh

Expected output:
- text_ids
- codes
- condition
- emo_vec
- train_manifest.jsonl
- val_manifest.jsonl
- stats.json

After completion check disk usage.


## 7. Generate full GPT prompt/target pairs

bash GENERATE_GPT_PAIRS.sh

Expected:
- gpt_pairs_train.jsonl
- gpt_pairs_val.jsonl


## 8. Short A40 benchmark

bash BENCHMARK_A40.sh

Default:
- batch size 1
- gradient accumulation 4
- AMP
- 50 optimizer steps

Purpose:
- verify full training path
- observe VRAM
- observe checkpoint size
- measure sec/step


## 9. Proper performance benchmark

MAX_STEPS=500 bash BENCHMARK_A40.sh

Use measured sec/step to calculate:
- epoch duration
- 1.5 epoch duration
- 2 epoch duration
- expected GPU rental cost


## 10. Full Serbian training

Only after benchmark numbers are reviewed:

bash TRAIN_FULL.sh

Defaults:
- batch size 1
- gradient accumulation 4
- 2 epochs
- learning rate 2e-5
- AMP

If training was interrupted and latest.pth exists,
TRAIN_FULL.sh automatically resumes using:

--resume auto


## Important files

Tokenizer:
bpe_serbian_13005.model

Vocabulary:
13005 tokens

Initial Serbian GPT:
gpt_serbian_13005_init.pth

GPT text layers:
(13006, 1280)

Dataset:
ParlaSpeech-RS

Dataset size:
290778 original samples
~896.22 hours
628 speakers

Prepared split plan:
parlaspeech_sr_split_plan_v3.jsonl

Expected prepared dataset:
~304450 samples
~896.219 hours

Serbian tokenizer test:
UNK rate = 0.000447% on 10000 random samples


## Stop conditions

Stop and diagnose before continuing if:

- SHA256 validation fails
- missing audio > 0
- tokenizer vocab != 13005
- GPT strict dimensions differ from 13006 x 1280
- preprocessing produces missing feature files
- smoke training produces NaN/Inf loss
- CUDA OOM occurs
- disk free space becomes unsafe
- latest.pth is not produced after training test


## Rule

Never spend long GPU time debugging.

First:
preflight -> smoke -> 50 steps -> 500 steps

Only then:
full training.