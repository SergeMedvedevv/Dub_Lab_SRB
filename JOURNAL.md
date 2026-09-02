# DubLab SRB — Development Journal

This journal documents the development of DubLab SRB: experiments, technical decisions, failed approaches, discoveries and results.

The purpose of keeping this journal is to preserve the real development history of the project and make the research process reproducible.

---

## Development Log

- Day 1 — First TTS experiments and Pinokio
- Day 2 — Serbian F5-TTS and model testing
- Day 3 — Datasets, ElevenLabs API and n8n
- Day 4 — Fish Audio S2 Pro and TTS comparison
- Day 5 — First real prototype pipeline
- Day 6 — First V1 dubbing test and expressive dubbing experiment
- Day 7 — Expressive dubbing research and first local TED-TTS prototype
- Day 8 — Serbian adaptation research and project consolidation
- ---

## Day 1 — First TTS experiments and Pinokio

### Objective

The first objective was to investigate whether existing AI voice synthesis tools could be used to create natural Serbian speech and eventually become part of an automated Serbian dubbing pipeline.

At this stage the focus was not on building the complete system, but on understanding what technology already exists and how well it works with Serbian.

### Pinokio

Pinokio was selected as one of the first environments for experimenting with locally hosted AI applications.

The idea was to use Pinokio as a convenient launcher for installing and testing different TTS projects without having to manually configure every dependency.

Several TTS solutions available through or alongside Pinokio were investigated.

### AllTalk TTS

AllTalk TTS v2 was one of the first systems considered.

The installation process encountered multiple dependency and environment issues. Work was done with Python environments, packages and model dependencies in an attempt to get the application running correctly.

AllTalk itself was **not fully investigated**, so no final conclusion about its Serbian capabilities was made.

It remains a possible system for future testing.

### Local Python environment

A separate Python virtual environment was created for the project.

During testing, several compatibility problems appeared between PyTorch-related packages and TorchCodec.

One of the errors was related to:

`audio_torch_device_type_cuda`

TorchCodec was removed while investigating the issue.

Attempts were also made to install different TorchCodec versions, but some required versions were unavailable for the installed Python/PyTorch configuration.

Eventually the TTS environment was successfully started and generation became possible.

### First Serbian speech tests

Once generation was working, Serbian text was tested using both writing systems.

**Latin Serbian:**

The model often interpreted Serbian words using English pronunciation rules.

**Cyrillic Serbian:**

The result was even less usable, with pronunciation sounding unrelated to natural Serbian speech.

Changing parameters such as generation speed, NFE steps and cross-fade duration did not solve the fundamental language problem.

### Important discovery

This established an important distinction for the project:

A TTS engine being technically capable of generating audio does **not** mean that it understands Serbian phonetics, pronunciation or prosody.

The quality of the underlying language model/checkpoint is much more important than the graphical interface or launcher used to run it.

Pinokio therefore became viewed primarily as a **tool for installing and launching AI projects**, rather than a solution to Serbian TTS by itself.

### Result of Day 1

The first experiments demonstrated that generic multilingual or unsupported TTS models were not sufficient for Serbian dubbing.

The next research question became:

> Can a TTS model specifically trained for Serbian provide significantly better results?

---

## Day 2 — Serbian F5-TTS and Custom Model Testing

### Objective

After the first experiments showed that generic TTS models could not pronounce Serbian correctly, the next goal was to find a model specifically trained for Serbian speech.

The main question was:

> Does a dedicated Serbian checkpoint solve the pronunciation problems observed during Day 1?

### F5-TTS

F5-TTS became the main platform for the next experiments.

The application provided a **Custom Model** option where a different model checkpoint, vocabulary and configuration could be loaded.

The default configuration referenced the standard F5-TTS model and vocabulary.

This confirmed that the TTS engine itself could be kept while replacing the underlying model with a Serbian-specific checkpoint.

### Serbian F5-TTS model

A community Serbian TTS model based on F5-TTS was discovered.

The model had been trained from scratch on a Serbian speech dataset.

The required model files were downloaded and connected to the F5-TTS interface through the Custom Model configuration.

During the first launch, additional model data was automatically downloaded and reconstructed.

After this process completed, Serbian speech generation successfully started.

This was the first locally running model in the project that demonstrated actual knowledge of Serbian pronunciation.

### Latin vs Cyrillic

Both Serbian writing systems were tested.

**Latin script produced noticeably better results.**

The model was able to pronounce a significant portion of the Serbian text correctly and sounded much closer to an actual Serbian speaker than the models tested previously.

Cyrillic input was also investigated, but Latin script proved more reliable for this particular checkpoint.

For further experiments, Serbian Latin was therefore selected as the preferred input format.

### Reference audio

F5-TTS uses reference audio and reference text to reproduce a target voice.

A Serbian reference recording was supplied together with its transcription.

During testing, an important problem appeared:

The generated speech sometimes contained fragments or words that appeared to originate from the reference material rather than from the requested generation text.

The output could therefore contain a mixture of:

- correct generated Serbian;
- altered words;
- fragments influenced by the reference;
- occasional unrelated speech.

### Hallucinations

Further testing confirmed that these errors were not simply caused by incorrect settings.

The creator of the Serbian checkpoint explicitly described the model as:

> "not production ready, still hallucinates"

This matched the observed behaviour.

The model clearly demonstrated Serbian language capability, but reliability was not sufficient for film dubbing.

For a dubbing pipeline, even occasional invented or substituted words are unacceptable because the generated dialogue must correspond precisely to the translated script.

### Comparison with ElevenLabs

ElevenLabs was tested as a quality reference.

The difference was immediately noticeable.

ElevenLabs produced significantly clearer Serbian speech with better pronunciation, more natural delivery and much higher consistency.

This established ElevenLabs as the first practical quality benchmark for the project.

The purpose of testing local models therefore changed slightly:

The goal was no longer simply to produce Serbian speech.

The goal became to find or develop a local/open model capable of approaching the Serbian quality demonstrated by ElevenLabs.

### Dataset research

The limitations of the existing Serbian checkpoint raised another question:

> Could a better Serbian TTS model eventually be trained or fine-tuned specifically for DubLab SRB?

This led to the first investigation of Serbian speech datasets.

ParlaSpeech was identified as an important potential source of Serbian speech data.

Possible future approaches were considered:

- fine-tuning an existing multilingual TTS model;
- training a Serbian-specific model;
- improving an existing Serbian checkpoint;
- building or cleaning a dedicated Serbian speech dataset;
- generating supplementary controlled speech data.

GPU requirements and the possibility of renting cloud GPUs for training were also discussed.

Local training was deliberately not made a priority because model training can require substantial GPU resources and long processing times.

### Result of Day 2

Day 2 produced the first meaningful Serbian TTS result.

The Serbian F5-TTS checkpoint proved that an open/local model can learn Serbian pronunciation, but also demonstrated that language support alone is not enough.

Reliability, prosody, pronunciation, voice quality and resistance to hallucinations are all critical for dubbing.

At the end of Day 2:

**F5-TTS Serbian** — useful experimental model, but not production-ready.

**ElevenLabs** — current benchmark for Serbian TTS quality.

**Serbian datasets / fine-tuning** — identified as an important future research direction.

---

## Day 3 — Datasets, ElevenLabs API and n8n Integration

### Objective

After establishing ElevenLabs as the current Serbian TTS quality benchmark, the next objective was to investigate how it could be integrated into an automated dubbing pipeline.

At the same time, research continued into Serbian speech datasets and the possibility of eventually training or fine-tuning an independent Serbian TTS model.

The main practical goal of the day became:

> Generate Serbian speech automatically through an API rather than manually through a web interface.

### Serbian speech datasets

Research continued into datasets that could potentially be used for future Serbian TTS development.

ParlaSpeech was investigated as one of the most interesting available resources.

The structure and possible download methods were examined, with the intention of later studying:

- available Serbian speech;
- audio quality;
- transcription quality;
- speaker diversity;
- dataset structure;
- suitability for TTS training or fine-tuning.

At this stage, training a model was deliberately postponed.

The priority remained building a working dubbing pipeline using the best technology currently available.

### ElevenLabs API

Because ElevenLabs produced the best Serbian speech during previous tests, its API became the first candidate for automated TTS generation.

API access was investigated and confirmed.

An API key was created for development purposes.

A Voice ID was selected so that requests could target a specific voice.

The multilingual ElevenLabs model was selected for Serbian generation.

This changed ElevenLabs from a manual testing tool into a component that could potentially be controlled automatically.

### n8n

n8n was selected as the first workflow automation platform for DubLab SRB.

The long-term idea is to use workflow automation to connect multiple stages of the dubbing process rather than manually moving files between applications.

Potential future stages include:

- receiving source video/audio;
- speech recognition;
- speaker identification;
- translation;
- TTS generation;
- file management;
- audio processing;
- synchronization;
- final reconstruction.

For the first experiment, only one connection was required:

**n8n → ElevenLabs API**

### First HTTP Request

An HTTP Request node was created inside n8n.

The request was configured to communicate with the ElevenLabs Text-to-Speech API.

The configuration included:

- POST request;
- ElevenLabs TTS endpoint;
- API authentication;
- Voice ID;
- JSON request body;
- Serbian test text;
- multilingual TTS model;
- binary/file response.

A short Serbian sentence was used as the first automated test.

The workflow executed successfully and n8n displayed a green successful execution status.

Initially, this appeared to indicate that the first automatic Serbian MP3 had been generated.

### Unexpected response

Inspection of the returned binary data revealed a problem.

Instead of:

`audio/mpeg`

the response contained:

`text/html`

The returned file therefore was not an MP3.

It was an HTML page.

The HTML response was downloaded and inspected.

This revealed that the problem was not caused by:

- the Serbian text;
- the Voice ID;
- the JSON structure;
- the n8n HTTP node;
- the basic workflow logic.

The request was being redirected because of regional access restrictions.

### Infrastructure discovery

n8n was running on a VPS rather than on the local development computer.

This was an important architectural detail because API requests originate from the VPS IP address.

The existing VPS used an IP associated with Saint Petersburg / Russia.

Therefore:

**Local computer in Serbia → n8n VPS → ElevenLabs**

meant that ElevenLabs saw the VPS network location rather than the developer's local Serbian connection.

This explained why ElevenLabs worked normally through the local browser while the same service failed when called from n8n.

### Direct API test

A direct request to the ElevenLabs API was also tested from the normal browser connection.

The API returned a structured JSON response rather than the regional restriction page.

Although the unauthenticated request itself produced a workspace-related error, it confirmed an important point:

The API endpoint was reachable from the normal Serbian internet connection.

This further isolated the problem to the VPS network location.

### Important conclusion

The n8n workflow itself was not considered a failure.

In fact, the experiment successfully demonstrated several important components:

- n8n could construct the request;
- the API endpoint could be called;
- authentication and request structure had been configured;
- binary responses could be received;
- the workflow architecture was viable.

The remaining problem was infrastructure-related.

The next requirement therefore became:

> Move the workflow to a VPS with a suitable European IP address.

### European VPS research

Several European VPS providers were considered:

- Hetzner
- OVHcloud
- Scaleway
- Contabo
- netcup

Hetzner became the leading candidate because of its European infrastructure, pricing, Docker support and popularity for self-hosted development environments.

A possible future server architecture was outlined:

Ubuntu  
→ Docker  
→ Docker Compose

with services such as:

- n8n;
- PostgreSQL;
- reverse proxy / HTTPS;
- FFmpeg;
- speech recognition components;
- future AI services.

The intention is not to build all of this immediately.

The infrastructure should grow only when required by the working prototype.

### Development strategy adjustment

At this stage an important project decision was made.

Instead of immediately spending resources on training a new Serbian TTS model, the project would first attempt to combine the best existing technologies into one complete pipeline.

The objective is to answer a more fundamental question:

> How good can AI-assisted Serbian film dubbing be today if the strongest available components are combined correctly?

Only after establishing that baseline will it make sense to decide which components need to be replaced or independently developed.

### Result of Day 3

Day 3 produced the first real automation architecture for DubLab SRB.

The ElevenLabs integration reached the API level, and the cause of the failed audio response was successfully isolated to the VPS network location rather than the workflow itself.

Current status:

**ElevenLabs API** — technically integrated and ready for further testing from suitable infrastructure.

**n8n** — selected as the initial workflow orchestration system.

**Current VPS** — unsuitable for ElevenLabs because of its network location.

**European VPS** — next infrastructure requirement.

**ParlaSpeech / Serbian datasets** — retained for future TTS research and fine-tuning.

The project is now moving from isolated TTS experiments toward an actual end-to-end Serbian dubbing prototype.

---

## Day 4 — Fish Audio S2 Pro and Definition of the First MVP

### Objective

While the main infrastructure work was temporarily paused, research continued into alternative TTS systems that could potentially compete with ElevenLabs for Serbian speech generation.

The goal was not simply to collect more models.

The objective was to determine whether another modern multilingual TTS system could provide Serbian speech of sufficient quality for film dubbing.

### Fish Audio S2 Pro

Fish Audio S2 Pro was identified as a particularly interesting candidate.

Unlike several previously investigated multilingual systems, its supported language list explicitly includes:

- `sr` — Serbian
- `hr` — Croatian
- `bs` — Bosnian

This made Fish Audio significantly more relevant to DubLab SRB than models where Serbian support was uncertain or unofficial.

The model also attracted attention because of its broader research potential, including available model weights and possibilities for future fine-tuning.

### Serbian testing

Serbian speech was tested directly through Fish Audio without installing the full model locally.

The first tests demonstrated that Fish Audio genuinely understands Serbian and can generate intelligible Serbian speech.

A more difficult test was then created to evaluate pronunciation and prosody.

The test contained:

- č, ć, š, ž and đ;
- long and short sentences;
- questions;
- emotional phrases;
- numbers;
- conversational Serbian;
- words with more difficult pronunciation.

The exact same Serbian text was then generated using ElevenLabs.

This allowed a direct comparison rather than evaluating the systems using different samples.

### Fish Audio vs ElevenLabs

Fish Audio produced a surprisingly usable result.

The speech was clearly Serbian and substantially better than the earlier unsupported or experimental TTS systems.

However, an important difference became apparent during direct comparison.

**ElevenLabs handled Serbian stress and prosody more naturally.**

Words were generally stressed more convincingly and sentences sounded closer to natural spoken Serbian.

Fish Audio occasionally produced pronunciation or stress patterns that made the speech sound less native even when the words themselves were understandable.

For film dubbing this distinction is important.

A technically correct sentence is not sufficient if the audience constantly notices unnatural stress or rhythm.

### Current TTS ranking

Based on practical testing performed so far:

**ElevenLabs**

Current Serbian quality benchmark.

Best combination observed so far of pronunciation, stress, naturalness and consistency.

**Fish Audio S2 Pro**

Promising alternative with explicit Serbian support.

Not currently as convincing as ElevenLabs in Serbian prosody, but important for future experimentation and possible fine-tuning.

**F5-TTS Serbian**

Demonstrates real Serbian language capability, but hallucinations and inconsistent generation currently prevent reliable dubbing use.

### Fish Audio as a future research candidate

Fish Audio will not be discarded.

Its importance to the project is different from ElevenLabs.

ElevenLabs currently represents:

> What quality can we achieve now?

Fish Audio potentially represents:

> What could we improve or customize ourselves later?

A future experiment may investigate fine-tuning Fish Audio using a high-quality Serbian speech dataset to determine whether Serbian stress, pronunciation and prosody can be improved.

This is not currently a priority.

### Defining the first MVP

After several days of testing individual technologies, the project direction was simplified.

The immediate objective is **not**:

- dubbing an entire film;
- training a new TTS model;
- building a fully automated production system;
- testing every available AI model.

The first MVP will instead answer one question:

> Can the best currently available technologies be combined to produce a short Serbian-dubbed film scene that is genuinely watchable?

### MVP target

The first target is:

**One complete 3–5 minute film scene.**

Preferably containing two or three characters.

The scene should be processed from the original source through to a finished Serbian version.

The target pipeline is approximately:

Source video  
→ extract audio  
→ separate dialogue from background audio  
→ speech recognition  
→ speaker diarization  
→ translation into Serbian  
→ assign voices to characters  
→ Serbian TTS  
→ synchronize generated dialogue  
→ restore music and sound effects  
→ final audio mix  
→ finished Serbian-dubbed video

### Speaker diarization

An important requirement was identified during pipeline planning.

The system must know **who is speaking and when**.

Speaker diarization technology can assign dialogue segments to different speakers, for example:

`SPEAKER_01`  
`SPEAKER_02`  
`SPEAKER_03`

Tools such as WhisperX combined with speaker diarization models are candidates for this stage.

This means that the system may not require manually separating every character into an individual audio track before transcription.

Instead, speech recognition, timestamps and speaker identity can potentially be extracted automatically.

### Dialogue separation

Another major challenge is preserving the original film atmosphere.

The final Serbian dialogue should coexist with:

- music;
- ambient sound;
- environmental noise;
- sound effects.

Therefore, dialogue separation will become an important research stage.

Source-separation systems such as Demucs and more specialized dialogue/music/effects separation models will be investigated.

The objective is to remove or suppress the original dialogue while preserving as much of the original soundtrack as possible.

### Prototype philosophy

The first prototype does not need to be completely automated.

Manual editing is acceptable.

The purpose of the MVP is to establish the **maximum achievable quality**, not the minimum number of mouse clicks.

Once a convincing 3–5 minute result exists, each manual stage can be examined and gradually automated.

This avoids spending large amounts of time automating a pipeline before knowing whether its final output is actually worth watching.

### Future demonstration set

After one scene is completed successfully, the same process should be tested on several different types of scenes.

Possible examples:

- calm two-person dialogue;
- emotional conversation;
- fast dialogue;
- multiple speakers;
- dialogue over music;
- scenes with significant environmental sound.

Approximately 3–5 short examples would provide a much better demonstration of the technology than a single carefully selected scene.

### Result of Day 4

Fish Audio S2 Pro was confirmed as a genuine Serbian-capable TTS system and retained as a promising future research candidate.

ElevenLabs remains the current benchmark for Serbian dubbing quality.

More importantly, the project now has a clearly defined first milestone:

**Create one complete, watchable 3–5 minute Serbian-dubbed film scene using the best available technologies.**

Only after achieving this result will the project focus heavily on automation, optimization and independent model development.

# Day 5 — First Real Prototype Pipeline

## 🎯 Goal of the Day

Move from testing separate tools to processing a real movie fragment and build the first working part of the DubLab SRB pipeline:

**audio separation → speech recognition → timestamps → speaker separation → dubbing script preparation**

For the test, we used a fragment from **Eyes Wide Shut**.

---

## ✅ What We Did

### 1. Separated the Original Audio

Installed and launched **Ultimate Vocal Remover 5.6.0**.

For the first test, we selected:

`UVR-MDX-NET Voc FT`

The processing produced two separate tracks:

- `Vocals` — character speech;
- `Instrumental` — background without the main dialogue.

The result was very good for this quiet dialogue scene.

In the `Instrumental` track, the voices were almost completely removed, while the room ambience and traffic sounds outside the window remained.

Even louder speech and shouting were removed quite cleanly.

**Conclusion:** for Prototype V1, the UVR result is good enough, so we decided not to test additional separation models yet.

---

### 2. Installed WhisperX

Created a separate Python environment:

`G:\DubLabSRB\whisperx_env`

Python version:

`3.11.9`

WhisperX installed successfully, but the first run produced:

`Torch not compiled with CUDA enabled`

The problem was that a CPU-only version of PyTorch had been installed.

We removed it and installed the CUDA version.

After verification:

`True`

`NVIDIA GeForce RTX 2080`

WhisperX was successfully running on the GPU.

---

### 3. Transcribed the English Dialogue

Instead of using the original movie audio, we used the cleaned speech track:

`1_BigEyes_(Vocals).wav`

WhisperX was launched with the `medium` model and English explicitly specified.

The result was good:

- dialogue was recognized;
- accurate timestamps were created;
- the long conversation was divided into individual lines;
- `.json`, `.srt`, `.vtt`, `.tsv`, and `.txt` files were generated.

At this point we already had the basic structure:

`start → end → text`

---

### 4. Added Speaker Diarization

Connected **pyannote** through Hugging Face.

For this scene, we already knew there were two speakers, so the diarization was limited to two voices.

After processing, WhisperX added:

`SPEAKER_00`

`SPEAKER_01`

By checking the dialogue, we identified:

`SPEAKER_00 = BILL`

`SPEAKER_01 = ALICE`

A few very short lines remained marked as `UNKNOWN`, but this was not critical for the first prototype.

---

### 5. Created a Readable Dialogue List

The JSON file was inconvenient to inspect manually, so we created a separate readable text file.

Example:

`24.327 → 25.708 | ALICE | Tell me something.`

`31.171 → 38.357 | ALICE | Those two girls at the party last night?`

`60.188 → 60.448 | BILL | What?`

This made it much easier to check speaker assignment and timing.

---

### 6. Created a Working Dubbing CSV

The diarized transcript was automatically converted into a structured table:

`start | end | character | english | serbian`

The scene contained approximately **96 dialogue lines**.

`SPEAKER_00` and `SPEAKER_01` were automatically converted into `BILL` and `ALICE`.

The `serbian` column was initially left empty.

---

### 7. Translated the Scene into Serbian

The entire dialogue was translated and the `serbian` column was filled.

The translation was prepared specifically for future dubbing rather than as a purely literal translation.

The main considerations were:

- avoid making short lines unnecessarily long;
- preserve the character and tone of the dialogue;
- preserve strong or explicit language when needed;
- keep the translation natural;
- consider the original line duration where possible.

The finished file:

`dubbing_script_SR.csv`

We now had a complete dubbing script with timestamps, characters, the original English text, and Serbian translation.

---

## ⚠️ What We Noticed

WhisperX works well, but very quiet or very short speech may still be missed or recognized incorrectly.

Diarization can also be uncertain with extremely short exclamations or fragments.

For Prototype V1, these limitations are acceptable and do not block further work.

---

## 💡 Main Result of the Day

For the first time, we had not just a collection of separate AI experiments, but a real working chain:

**movie → dialogue separation → transcription → timestamps → speakers → translation**

Most importantly, the result is now stored in a structured format that can be processed automatically.

Individual dialogue lines no longer need to be copied manually.

---

## 🔜 Next Step

Connect TTS and automatically generate Serbian dialogue:

- ALICE with one voice;
- BILL with another voice;

then place the generated lines back onto the original timestamps and mix them with the `Instrumental` track.

This will become the first real V1 dubbed scene.

# Day 6 — First V1 Dubbing Test and First Expressive Dubbing Experiment

## 🎯 Goal of the Day

Continue Prototype V1 from the prepared dubbing script and finally hear Serbian dialogue inside the real movie scene.

The main tasks were:

**CSV → Serbian TTS → character voice selection → automatic timeline placement → first watchable dubbing test**

After evaluating V1, we also made the first small experiment with a more expressive dubbing approach.

---

## ✅ What We Did

### 1. Connected ElevenLabs API

Created an ElevenLabs API key with access limited to **Text to Speech**.

The key was stored locally as a Windows environment variable instead of being written directly into the Python script.

Installed the ElevenLabs Python SDK inside the existing WhisperX environment.

At first, we tried selected Voice Library voices for ALICE and BILL, but the Free plan did not allow those voices to be used through the API.

For the test, we switched to available default voices.

This allowed the API to work successfully.

---

### 2. Automated Serbian TTS Generation

Created:

`generate_test.py`

The script reads:

`dubbing_script_SR.csv`

For every line it automatically:

- reads the character name;
- reads the Serbian text;
- selects the correct Voice ID;
- sends the text to ElevenLabs;
- saves the generated audio file.

The first **10 dialogue lines** were generated automatically.

This confirmed that the following process works:

**CSV → character → Serbian text → voice selection → TTS audio**

No manual copying of individual lines was required.

---

### 3. Built the First Automatic Dubbing Timeline

Installed `pydub`.

Created:

`mix_test.py`

The script took the generated Serbian dialogue and placed each audio file at its original `start` timestamp over:

`1_BigEyes_(Instrumental).wav`

The result was saved as:

`Eyes_Wide_V1_TEST.wav`

The new audio track was then placed under the original movie fragment in a video editor.

---

## 🎬 First Real V1 Result

The automatic line placement worked very well.

The beginning of the Serbian lines matched the original dialogue positions correctly.

This was an important confirmation that:

**WhisperX timestamps → CSV → automatic timeline reconstruction**

works as intended.

For the first time, we could watch part of the real movie scene with automatically generated Serbian dialogue.

---

## ⚠️ Main V1 Problem — Dialogue Duration

The most obvious problem became clear immediately.

Short lines worked quite well.

Longer Serbian lines were often spoken much faster than the original actor.

For example:

- the Serbian TTS line could finish after 2–4 seconds;
- the original actor could continue speaking for several more seconds;
- the lips were still moving while the Serbian voice had already finished.

The TTS also generated its own rhythm and intonation rather than following the original acting performance.

This became the main quality limitation of V1.

---

### 4. Duration Analysis

Created:

`check_duration.py`

The script compares:

`target duration = end - start`

with the real duration of the generated TTS file.

Some results showed large differences.

Examples:

`Line 1 — target 1.381 s / generated 1.068 s`

`Line 2 — target 7.186 s / generated 2.090 s`

`Line 4 — target 8.671 s / generated 1.904 s`

`Line 10 — target 4.383 s / generated 2.461 s`

This confirmed that long lines were being compressed heavily by normal TTS.

---

## 💡 Important Observation About Timestamps

We also realized that:

`end - start`

does not always mean continuous speech.

An original actor may include:

- pauses;
- hesitation;
- stretched words;
- slower delivery;
- silence inside the line.

Therefore, simply forcing every generated line to occupy the entire `start → end` interval may not always be correct.

---

### 5. Time-Stretch Experiment

To test a simple solution, we used FFmpeg `atempo` to stretch generated speech without strongly changing pitch.

Created:

`stretch_test.py`

Two lines were tested:

`Line 1 → ×1.29`

`Line 10 → ×1.78`

Then a new mix was created with:

`mix_test_stretch.py`

Result:

`Eyes_Wide_V1_TEST_STRETCH.wav`

---

## 🎧 Time-Stretch Result

The smaller correction worked well.

The first line matched the timing better and still sounded natural.

The stronger ×1.78 stretch made the tenth line fit the original duration much better, but audible artifacts appeared.

The voice started to sound unstable, almost like two slightly different versions of the same speaker.

### Conclusion

Small duration corrections can be useful.

Strong post-processing stretch is not a good general solution for long dialogue lines.

The speech should ideally be generated closer to the required duration from the beginning.

---

### 6. Missed Quiet BILL Line

While watching the scene, we noticed that one short quiet BILL line between the 9th and 10th dialogue entries was missing.

The original WhisperX JSON was checked.

The line was not present there.

This confirmed that:

- the CSV conversion worked correctly;
- the generation script worked correctly;
- WhisperX itself had missed the quiet speech.

For now, this was recorded as an ASR limitation rather than treated as a major problem.

---

# First V2 Experiment

After seeing the limitations of normal TTS, we decided to test a second approach.

The idea was not to reproduce the actor perfectly, but to preserve the larger performance characteristics:

- pauses;
- speech rate;
- quiet or loud delivery;
- emotional intensity;
- general rhythm;
- approximate duration.

The goal became:

**same performance shape, new language**

---

### 7. Prepared ALICE Material for Expressive Dubbing

Original ALICE lines were cut from:

`1_BigEyes_(Vocals).wav`

using the timestamps already produced by WhisperX.

Several ALICE lines from the first part of the scene were prepared for testing.

A first timeline containing ALICE on the original positions was too long and included large silent gaps.

This was inefficient because the dubbing service charged for the entire audio duration.

---

### 8. Created a Short Expressive Dubbing Test

To reduce cost, the first four ALICE lines were joined with only short pauses between them.

The resulting file was approximately:

`19 seconds`

This became the standard short test fragment for comparing expressive dubbing systems.

---

### 9. ElevenLabs Dubbing Test

ElevenLabs Dubbing was tested on the 19-second ALICE fragment.

Croatian was used for the first experiment because Serbian was not available in the tested Dubbing interface.

### Result

The result was significantly better than normal TTS.

The generated translation preserved much more of:

- original pauses;
- pacing;
- overall delivery;
- emotional structure;
- approximate speech duration.

The difference was immediately noticeable.

The result felt much closer to the original acting performance than the normal TTS version.

---

## 💰 Cost Problem

The quality was good, but the credit consumption was high.

The short ~19-second test used several thousand credits.

A longer version with large silent gaps required much more.

This showed that sending long timelines with silence is inefficient.

It also showed that ElevenLabs Dubbing is currently too expensive for large-scale experimentation under the available project budget.

---

## 💡 Main Result of the Day

Day 6 produced two important conclusions.

### V1

The classic pipeline works:

**translation → TTS → automatic timeline placement**

but long dialogue lines lose the original timing and acting rhythm.

### V2

Expressive dubbing clearly has the potential to solve part of this problem.

The first test showed that preserving the original performance structure can produce a much more convincing result.

ElevenLabs became the first practical quality benchmark for expressive dubbing.

---

## 🔜 Next Step

Continue researching alternative expressive dubbing systems that may provide similar quality at a lower cost or with open-source/local inference.

Candidates to investigate:

- Dubformer;
- Rask AI;
- CAMB.AI;
- Perso AI;
- Meta SeamlessExpressive;
- open-source expressive speech models.

At the same time, keep V1 as a working baseline for comparison.

# Day 7 — Expressive Dubbing Research and First Local TED-TTS Prototype

## 🎯 Goal of the Day

Continue researching alternatives to expensive commercial expressive dubbing and understand whether the key part of V2 can be built locally.

The main question was:

**Can we preserve approximate emotion, pauses, pacing and dialogue duration without relying entirely on ElevenLabs Dubbing?**

Instead of searching only for one “all-in-one” dubbing service, we also started looking at a modular approach where different tools handle different parts of the pipeline.

---

## ✅ What We Did

### 1. Investigated Dubformer

Dubformer became one of the most technically interesting commercial candidates.

Its **Voice Acting / Emotion Transfer** concept is very close to the DubLab V2 requirement:

**reference performance + translated text + timing → synthesized speech with transferred delivery**

The technology is promising, but practical testing was blocked by the lack of useful free minutes and limited access to the more advanced API features.

### Conclusion

Dubformer remains an important candidate, but it is not convenient for low-budget experimentation at the moment.

---

### 2. Tested Rask AI

The same ALICE test material was processed through Rask AI.

The result was usable, but compared with the ElevenLabs benchmark:

- the voice differed noticeably from the original;
- the overall acting performance was preserved less accurately;
- pauses, pacing and emotional structure felt less connected to the source performance.

It also appeared that full voice cloning was limited or unavailable in the tested free mode.

### Conclusion

Rask works as an automatic dubbing service, but for our specific goal of preserving the original performance it was weaker than the ElevenLabs result.

---

### 3. Tested CAMB.AI

CAMB.AI was especially interesting because **Serbian was directly available** as a target language.

We used:

`End-to-End Dubbing`

with:

`MARS8-Instruct`

and the higher-quality / slower transcription mode.

MARS8-Instruct explicitly focuses on emotion and prosody control.

### Result

CAMB clearly tried to preserve part of the original intonation and delivery.

Positive:

- Serbian is supported;
- some prosodic information was preserved;
- the result was more expressive than simple TTS.

Problems:

- dialogue duration was less consistent;
- one Serbian line was not fully pronounced even though the word was present in the transcript;
- voice cloning was disabled in the tested mode;
- the overall performance still felt weaker than the ElevenLabs benchmark.

### Conclusion

CAMB is technically interesting, especially because of Serbian support, but the tested result was not yet strong enough for our V2 target.

---

### 4. Checked Perso AI

Perso AI was also investigated.

Serbian is supported by the platform, but it was not available for useful testing on the free plan.

Because the goal was research rather than buying subscriptions for every service, we decided not to pay only for this experiment.

### Conclusion

Perso remains untested for quality.

---

## 5. Meta SeamlessExpressive Access

The request for access to:

`facebook/seamless-expressive`

was approved on Hugging Face.

This model is particularly interesting because it was designed specifically for **cross-lingual expressivity preservation**.

We checked the available Hugging Face Spaces using the model.

Unfortunately, the Spaces failed with runtime/memory errors.

One of them exceeded:

`16 GiB`

of available memory.

### Hardware Research

We checked possible cloud GPU options.

A short experiment on a 24 GB GPU such as an RTX 3090 would cost only a few dollars or less, making cloud testing realistic.

However, Meta SeamlessExpressive does not directly solve the Serbian speech-output problem, so cloud testing was postponed rather than treated as an immediate priority.

---

# Moving Toward a Modular Architecture

During the research, an important idea emerged:

**DubLab does not necessarily need one model that performs every task.**

We can build the final system from specialized components.

A possible V2 structure:

**translation → emotion / prosody control → duration control → Serbian speech → voice identity → timeline**

This shifted the research from:

> “Find a free ElevenLabs replacement”

toward:

> “Find the strongest tool for each individual part of the dubbing pipeline.”

---

## 6. TED-TTS Selected for Local Testing

TED-TTS became particularly interesting because it provides several features directly related to problems already found in V1:

- emotion reference;
- emotion control;
- global duration control;
- local segment duration control;
- speaker reference / voice cloning.

TED-TTS is built on top of **IndexTTS-2**.

The official demo examples sounded promising, especially the duration and emotion-control examples.

We decided to install it locally and test whether it could solve the problem of:

**generated speech being much shorter than the original actor performance.**

---

# 7. TED-TTS Installation

TED-TTS was installed separately from the existing WhisperX environment.

Project location:

`G:\DubLabSRB\TED-TTS`

Git was not available in Windows PATH, so the repository was downloaded manually as a ZIP from GitHub and extracted into the project folder.

Installed `uv` and created the project environment.

---

## ⚠️ DeepSpeed Problem on Windows

The first dependency installation failed because TED-TTS required:

`deepspeed==0.17.1`

DeepSpeed failed to compile on Windows.

Because DeepSpeed is not required for basic inference, its dependency was removed from:

`pyproject.toml`

Then the environment was rebuilt using:

`uv lock`

and:

`uv sync`

The environment installed successfully without DeepSpeed.

---

## 8. Downloaded IndexTTS-2 Weights

TED-TTS uses the IndexTTS-2 model underneath.

The official checkpoints were downloaded into:

`G:\DubLabSRB\TED-TTS\checkpoints`

The model files included several large components, including GPT and acoustic model weights.

---

## 9. CUDA / PyTorch Setup

At first, the TED-TTS environment contained:

`PyTorch 2.8.0+cpu`

and:

`CUDA available: False`

The existing NVIDIA driver was also relatively old.

The NVIDIA driver was updated from:

`536.99`

to:

`610.88`

After several attempts, it became clear that `uv` required an explicit PyTorch CUDA backend.

The final working installation used:

`torch 2.8.0 + CUDA 12.8`

Final verification:

`PyTorch: 2.8.0+cu128`

`CUDA available: True`

`CUDA: 12.8`

`GPU: NVIDIA GeForce RTX 2080`

The `uv` cache was also moved away from the system disk during installation because the large CUDA PyTorch package temporarily exhausted free space on C:.

---

## 10. Additional Environment Fixes

The first TED-TTS launch revealed several missing/incompatible dependencies.

Installed:

`einops`

A compatibility problem also appeared with NumPy 2.x.

NumPy was downgraded to:

`1.26.4`

After these fixes, TED-TTS successfully initialized.

---

# 🎉 First Successful Local TED-TTS Inference

The basic inference test finally completed successfully.

All main models initialized and the system began real speech generation using:

`cuda:0`

The RTX 2080 handled inference, but almost at its limit.

Peak VRAM usage was approximately:

`7.8 / 8.0 GB`

GPU utilization reached almost 100% during some stages.

### Conclusion

**TED-TTS can run locally on an RTX 2080 8 GB.**

However, the available VRAM margin is extremely small.

For larger experiments, repeated parameter testing or future training, a rented GPU with approximately 24 GB VRAM will be much more practical.

---

# 11. First Emotion Reference Test

An original ALICE line was prepared as:

`alice.wav`

The tested line:

`Those two girls at the party last night?`

TED-TTS was given the original ALICE audio as an emotion reference.

### Result

The system clearly reacted to the source performance.

We could hear:

- attempts to preserve pauses;
- changes in emotional delivery;
- some similarity in the rhythm between words.

However:

- the original line lasted about 7 seconds;
- TED-TTS generated roughly 4 seconds;
- one word that ALICE stretches slightly in the original was spoken normally;
- local prosody was still far from an exact copy.

### Conclusion

Emotion reference works, but emotion reference alone does not preserve the original duration or all local details of the performance.

---

## 12. Duration Control Test

The same line was then tested with a target duration of approximately:

`7.186 seconds`

TED-TTS successfully generated a line close to the requested 7-second duration.

This was important because the model did **not** simply generate a short line and append silence.

It attempted to redistribute:

- speech;
- pauses;
- pacing;
- emotional delivery

across the requested duration.

### Result

The duration control itself worked.

However, the model did not stretch or pause in exactly the same places as the original actor.

Some emotional accents appeared in the wrong positions.

The result sounded somewhat artificial — similar to an old low-budget movie dub — but the mechanism itself was clearly working.

---

## 13. Emotion Representation

During the emotion-controlled test, TED-TTS displayed an internal emotion vector.

Example:

`happy        0.000`

`angry        0.100`

`sad          0.100`

`afraid       0.100`

`disgusted    0.100`

`melancholic  0.100`

`surprised    0.100`

`calm         0.450`

This showed that emotion is represented as a mixture of several components rather than a single label.

This may allow more precise manual control in future experiments.

---

## ⚠️ What We Learned

TED-TTS is not yet a ready solution for DubLab, but it solves several important problems that ordinary TTS does not.

It can:

- react to an emotional reference;
- control total generated duration;
- redistribute speech across the requested time instead of simply stretching finished audio;
- potentially control emotion and duration at a more detailed segment level;
- run locally without paying per generated minute.

At the same time:

- local prosody is not automatically copied exactly;
- emotional accents can appear in the wrong places;
- the RTX 2080 is operating extremely close to its VRAM limit;
- Serbian support still needs to be investigated separately.

---

## 💡 Main Result of the Day

Day 7 changed the direction of the research.

Instead of looking only for another commercial dubbing website, we confirmed that a **local modular expressive-speech pipeline is technically possible**.

TED-TTS successfully demonstrated two mechanisms that are especially important for DubLab:

**emotion control + duration control**

The quality still requires experimentation, but the technology is promising enough to continue.

---

## 🔜 Next Step

Continue TED-TTS experiments with:

- manual emotion control;
- speaker reference / voice cloning;
- combined emotion + duration control;
- local segment duration control;
- testing whether the same approach can eventually work with Serbian.

Commercial systems remain useful as benchmarks, but the main research direction is moving toward a controllable local V2 pipeline.

## Day 8 — Serbian Adaptation Research and Project Consolidation

### 🎯 Goal of the Day

Continue from the successful local TED-TTS / IndexTTS-2 expressive speech experiments from Day 7.

At the beginning of the day, the main technical question was:

> Can the expressive V2 system that already controls speaker identity, emotion and duration also generate usable Serbian?

The second goal became clear after the Serbian test failed:

> Determine what would be required to adapt IndexTTS to Serbian and decide whether it makes sense to start that work now.

Later, because paid GPU training was not currently available, the project focus shifted toward documentation and infrastructure that could be completed without additional cost.

---

### 🔗 Dependencies / Starting Point

Day 8 depended directly on the working environment created in Day 7.

Available:

- TED-TTS;
- IndexTTS-2;
- Python 3.11.9;
- PyTorch 2.8.0+cu128;
- CUDA 12.8;
- RTX 2080 8 GB;
- downloaded IndexTTS checkpoints;
- working speaker reference;
- working emotion control;
- working duration-control functions;
- Eyes Wide Shut prototype material;
- Serbian translations from Prototype V1.

The important starting point was:

```text
expressive English generation = working
```

The unanswered question was:

```text
Serbian generation = ?
```

---

### 1. Reviewed the TED-TTS Inference Modes

Before continuing the language test, the available TED-TTS controls were reviewed more carefully.

The inference script exposed six modes:

```text
Mode 0
Mode 1
Mode 2
Mode 3
Mode 4
Mode 5
```

The main functions included:

```text
speaker reference
emotion reference audio
8-dimensional emotion vector
per-segment emotion text
global duration control
local / per-segment duration control
```

This confirmed that TED-TTS had exactly the kind of control required for the experimental V2 direction.

---

### 2. Emotion Vector Control

A more focused emotion test was made using a real line from Eyes Wide Shut.

Example:

```text
Those two girls at the party last night?
```

Instead of using a generic neutral generation, an explicit emotion vector was provided.

Example structure:

```text
happy        0.00
angry        0.25
sad          0.00
afraid       0.10
disgusted    0.10
melancholic  0.05
surprised    0.05
calm         0.45
```

The intention was to create a delivery closer to:

```text
suspicious
restrained
slightly confrontational
```

rather than simply making the voice sound "angry."

This was important because film performance usually contains mixed emotional states rather than one simple emotion label.

---

### 💡 Expressive Control Result

The experiment confirmed that the useful direction for V2 is:

```text
speaker reference
+
emotion information
+
duration information
+
target dialogue
```

rather than:

```text
text
+
generic TTS voice
```

The expressive part of the system remained promising.

The next problem was language.

---

### 3. Tested Serbian Text

Serbian dialogue was passed to the working TED-TTS / IndexTTS-2 setup.

The result was clearly unusable.

The model did not produce natural Serbian pronunciation.

Instead, it behaved approximately like:

```text
Serbian text
↓
interpreted through English / supported-language phonetics
↓
incorrect pronunciation
```

The result was not simply a bad Serbian accent.

The model fundamentally did not understand Serbian phonetics correctly.

---

### ⚠️ Main Finding

The expressive model solved several problems that V1 could not solve:

```text
speaker identity
emotion
duration
performance control
```

but failed at:

```text
Serbian language support
```

This produced a very clear comparison.

#### ElevenLabs / V1

```text
Serbian pronunciation = GOOD
Emotion / duration control = LIMITED
```

#### TED-TTS / IndexTTS-2

```text
Emotion / duration control = PROMISING
Serbian pronunciation = BAD
```

The future goal became:

```text
Serbian
+
IndexTTS-style expressive control
```

---

### 4. Checked Croatian as a Possible Shortcut

Because Serbian and Croatian are closely related, Croatian support was investigated as a possible workaround.

The idea was:

```text
if Croatian is supported
↓
perhaps Serbian Latin text could be handled sufficiently well
```

However, the tested IndexTTS-2 setup did not provide proper Croatian support either.

Therefore:

```text
Croatian ≠ shortcut to Serbian
```

This route was rejected.

---

### 5. Investigated Serbian Fine-Tuning

The next question became:

> How can IndexTTS be taught Serbian?

This is more complicated than ordinary voice fine-tuning.

The missing capability is not only:

```text
new speaker
```

but:

```text
new language
```

A Serbian adaptation may require work on several levels:

- Serbian speech data;
- accurate transcripts;
- tokenizer / vocabulary coverage;
- Serbian phonetics;
- text-to-speech alignment;
- model fine-tuning;
- evaluation of pronunciation and prosody.

This became the central Serbian model research direction.

---

### 6. Important Distinction: Voice Training vs Language Adaptation

A normal speaker adaptation teaches:

```text
how a person sounds
```

Serbian adaptation must also teach:

```text
how Serbian is pronounced
```

Therefore a small voice sample alone cannot solve the problem.

The model needs enough Serbian speech and text to learn relationships between:

```text
letters / tokens
↓
Serbian phonetics
↓
speech
```

This made dataset research necessary.

---

### 7. Investigated Serbian Speech Data

Existing Serbian speech datasets remained an important research direction.

One previously identified resource was:

```text
ParlaSpeech
```

The future dataset requirements were clarified.

Useful training material should ideally contain:

```text
clean Serbian audio
+
accurate Serbian transcript
+
sufficient duration
+
speaker diversity
+
phonetic diversity
```

For movie dubbing, expressive or conversational speech would eventually be especially valuable.

---

### 8. Investigated IndexTTS-2.5

A newer version, IndexTTS-2.5, was investigated.

The immediate question was:

> Can the current IndexTTS-2 environment simply be upgraded?

Technically, moving to the newer version was possible as a separate installation / update task.

However, the important question was not:

```text
Is 2.5 newer?
```

It was:

```text
Does 2.5 solve Serbian?
```

The answer was:

```text
NO
```

There was still no ready Serbian model that solved the current language problem.

---

### 💡 Decision: Do Not Upgrade Yet

The current TED-TTS / IndexTTS-2 environment was already working.

Installing a newer model would introduce:

- another dependency cycle;
- new model downloads;
- possible CUDA problems;
- possible compatibility problems;
- more disk usage.

Without Serbian support, this would not solve the main problem.

Decision:

```text
KEEP CURRENT WORKING ENVIRONMENT
```

and:

```text
POSTPONE IndexTTS-2.5 INSTALLATION
```

until there is a concrete technical reason to upgrade.

---

### 9. Can the Earlier Serbian F5 Model Be Used?

Another idea was investigated:

> Can we simply give IndexTTS the earlier experimental Serbian model used during the F5-TTS tests?

This would have been convenient because that model had at least some Serbian language knowledge.

However, the models are based on different architectures.

They use different:

- model weights;
- network structures;
- tokenization;
- vocabulary;
- training pipelines.

Therefore:

```text
F5-TTS Serbian checkpoint
≠
IndexTTS checkpoint
```

The old Serbian model cannot simply be loaded into IndexTTS.

---

### 💡 What Can Be Reused

Although its weights are incompatible, the previous Serbian research is not useless.

Potentially reusable elements include:

- knowledge about Serbian datasets;
- Serbian test sentences;
- pronunciation evaluation methodology;
- Latin vs Cyrillic observations;
- future training material.

So:

```text
reuse the research
not the checkpoint
```

---

### 10. Training Infrastructure Question

Serbian adaptation would require significantly more compute than simple inference.

The local:

```text
RTX 2080 8 GB
```

was already operating near its VRAM limit during TED-TTS inference.

Therefore serious training / fine-tuning on the local GPU was not considered the preferred route.

The more realistic architecture became:

```text
prepare dataset locally
↓
prepare configuration locally
↓
rent stronger GPU
↓
train / fine-tune remotely
↓
download resulting model
↓
test locally
```

---

### 11. Budget Decision

GPU rental requires additional project budget.

At this point there was no budget available for starting rented-GPU training immediately.

Decision:

```text
WAIT FOR THE NEXT SALARY
```

and:

```text
DO NOT START PAID TRAINING YET
```

This did not stop the project.

There were still many useful tasks that could be completed without spending money.

---

### 12. Development Strategy Changed Temporarily

The project was divided into two groups of work.

#### Expensive / postponed work

```text
Serbian model training
GPU rental
large fine-tuning experiments
```

#### Free work available now

```text
GitHub
documentation
journal
roadmap
workflow
Obsidian
research organization
training preparation
```

This prevented the project from becoming blocked by the training budget.

---

### 13. Started Organizing the GitHub Repository

The existing DubLab SRB GitHub repository began to be turned into a real project repository rather than an empty placeholder.

The documentation structure included work on:

```text
README.md
JOURNAL.md
ROADMAP.md
WORKFLOW.md
```

The purpose was to separate different types of information.

#### README

Used for:

```text
what the project is
current objective
main architecture
current status
```

#### JOURNAL

Used for:

```text
what was actually done
day by day
including failures and conclusions
```

The same development history also began to be transferred into Obsidian.

#### ROADMAP

Used for:

```text
where the project is going
```

The roadmap was updated to reflect the new split between:

```text
stable V1
```

and:

```text
experimental V2 / Serbian model research
```

A new Roadmap version was kept instead of destroying the earlier one.

---

### 14. Updated the Project Roadmap

The main project principle remained:

> First prove the quality. Then automate it.

The updated roadmap separated the work into:

```text
Working Prototype
Evaluation
Automation
Serbian TTS Research
```

The important strategic change was that V1 and Serbian model research were no longer allowed to block each other.

---

### 15. Created a Detailed V1 Workflow

A separate:

```text
WORKFLOW.md
```

was created.

The purpose was different from the Journal.

The Journal explains:

```text
what happened
```

The Workflow explains:

```text
how to reproduce the working process
```

The V1 Workflow documented the pipeline from the original movie material to the reconstructed Serbian soundtrack.

---

### 16. Workflow Structure

The documented pipeline included:

```text
source movie
↓
UVR
↓
WhisperX
↓
alignment
↓
speaker diarization
↓
speaker mapping
↓
readable dialogue list
↓
dubbing CSV
↓
Serbian translation
↓
TTS
↓
timeline reconstruction
↓
duration analysis
↓
optional time-stretch
↓
final validation
```

The document also separated:

```text
V1 = stable / repeatable
```

from:

```text
V2 = experimental
```

This prevents future research experiments from breaking the documented working pipeline.

---

### 17. Documentation Principle

A new project rule became:

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
```

These documents should not duplicate each other unnecessarily.

Each has a different role.

---

### 18. Started the Obsidian Knowledge Base

Obsidian was selected as the main local project knowledge base.

A vault was created for:

```text
Dub_Lab_SRB
```

The initial structure was organized into:

```text
00 Home
01 Project
02 Journal
03 V1
04 V2
05 Serbian Model
06 Research
07 Business
08 Mind Map
```

This separated technical work, research and business ideas while still allowing them to be connected through Obsidian links.

---

### 19. Why Obsidian Was Added

GitHub remains useful for:

- repository history;
- public documentation;
- code;
- stable project files.

Obsidian has a different purpose:

- internal knowledge;
- cross-links;
- research notes;
- model notes;
- experiments;
- business ideas;
- graph relationships.

The goal is not to duplicate GitHub completely.

The goal is to create a connected knowledge system around the project.

---

### 20. Started Cross-Linking the Project

The journal began to be transferred into individual Obsidian notes:

```text
Day 1
Day 2
Day 3
...
Day 8
```

The notes were also prepared for connections between topics such as:

```text
IndexTTS-2
F5-TTS
ElevenLabs
WhisperX
TED-TTS
V1
V2
Serbian Model
Serbian Datasets
Training Plan
```

This was the beginning of the actual Obsidian graph.

The aim was to avoid having the project stored only as a linear chronological journal.

---

### 21. Added PC ↔ Android Synchronization

Because the project notes should also be available on Android, a synchronization solution was set up.

Selected tool:

```text
Syncthing
```

Windows version used:

```text
Syncthing v2.1.3
```

The Windows instance was configured locally and the DubLab SRB vault folder was added.

Vault path:

```text
G:\DubLabSRB\ProgrammSS\Obsidian\Dub_Lab_SRB
```

The synchronized folder was labeled:

```text
Dub_Lab_SRB
```

---

### 22. Android Setup

On Android, the client used was:

```text
Syncthing-Fork
```

The PC and Android devices were paired using Syncthing device IDs.

A corresponding:

```text
Dub_Lab_SRB
```

folder was created on the phone and shared with the PC.

The folder was configured as:

```text
Send & Receive
```

so edits can synchronize in both directions.

---

### ✅ Synchronization Result

The synchronization successfully started working between:

```text
PC
↕
Android
```

This means the Obsidian project can now be used from both devices without requiring Obsidian's paid synchronization service.

---

### 💡 Main Result of the Day

Day 8 produced two important results.

#### Technical Result

The main V2 blocker was identified precisely:

```text
TED-TTS / IndexTTS-2 expressive control = promising
Serbian language capability = missing
```

Therefore the next real technical milestone became:

```text
Serbian adaptation
```

not another random TTS search.

#### Project Infrastructure Result

Because model training was postponed by budget, the project did not stop.

Instead, the foundation was strengthened:

```text
GitHub
+
Journal
+
Roadmap
+
Workflow
+
Obsidian
+
Syncthing
```

This turned DubLab SRB from a series of experiments into a documented research project.

---

### ✅ Status at the End of Day 8

#### Prototype V1

```text
STABLE BASELINE
```

#### TED-TTS / IndexTTS-2

```text
WORKING EXPERIMENTALLY
```

Strong points:

```text
speaker
emotion
duration
```

Weak point:

```text
Serbian
```

#### IndexTTS-2.5

```text
RESEARCHED
NOT INSTALLED
```

Reason:

```text
does not solve the Serbian problem
```

#### Serbian Model

```text
NEXT MAJOR R&D PROBLEM
```

Requires further work on:

```text
datasets
language adaptation
fine-tuning strategy
training infrastructure
```

#### GPU Rental

```text
POSTPONED
```

Reason:

```text
budget
```

#### GitHub Documentation

```text
IN PROGRESS / STRUCTURED
```

Main documents:

```text
README
JOURNAL
ROADMAP
WORKFLOW
```

#### Obsidian

```text
INSTALLED / STRUCTURED
```

Knowledge-base structure created.

#### Syncthing

```text
WORKING
```

PC ↔ Android synchronization established.

---

### 🔥 Day 8 Milestone

The project reached an important transition.

The technical problem was now clearly defined:

```text
V1 gives us Serbian.
V2 gives us performance control.

We need both.
```

At the same time, the project now had a documentation system capable of preserving the research and preventing repeated work.

---

### 🔜 Next Step

Until training budget becomes available:

- finish transferring Journal entries into Obsidian;
- add meaningful cross-links;
- create a V1 Overview;
- create a V2 Overview;
- create Serbian Model / Serbian Adaptation notes;
- organize Serbian Datasets;
- document the future fine-tuning plan;
- preserve the working TED-TTS environment;
- avoid unnecessary IndexTTS upgrades.

When budget becomes available, return to:

```text
Serbian adaptation
↓
rented GPU
↓
fine-tuning experiment
```

---

### 🔗 Related

- Day 7
- Prototype V1
- V1 Overview
- V2 Overview
- TED-TTS
- IndexTTS-2
- IndexTTS-2.5
- Expressive Control
- Emotion Control
- Duration Control
- Speaker Reference
- Serbian Model
- Serbian TTS Research
- Serbian Datasets
- ParlaSpeech
- Fine-tuning
- GPU Rental
- GPU Requirements
- F5-TTS
- ElevenLabs
- GitHub
- Journal
- Roadmap
- Workflow
- Obsidian
- Syncthing
- Mind Map
- Experiments

## Day 9 — Serbian Training Pipeline and RunPod Package Preparation

### 🎯 Goal of the Day

Continue from the Serbian adaptation problem identified on Day 8.

The previous stage established a clear target:

```text
V1 gives us Serbian.
V2 gives us expressive control.

We need both.
```

The next question was no longer:

> Which TTS system should be tested next?

It became:

> How do we prepare IndexTTS-2 for an actual Serbian adaptation experiment?

Because paid GPU training was still postponed, the goal of the day was not to start expensive training.

Instead, the objective became:

```text
prepare everything locally
↓
verify everything locally
↓
make the training package reproducible
↓
rent GPU only when the package is ready
```

This marked the transition from general Serbian-model research to concrete training engineering.

---

### 🔗 Starting Point

Available from the previous work:

- working TED-TTS / IndexTTS-2 inference environment;
- Python 3.11;
- CUDA / PyTorch environment;
- Serbian pronunciation problem confirmed;
- ParlaSpeech identified as a promising Serbian dataset;
- local RTX 2080 8 GB available for development and testing;
- rented GPU planned for serious training;
- no immediate GPU-rental budget.

The important project decision remained:

```text
DO NOT TRAIN EXPENSIVELY YET
```

but:

```text
PREPARE THE TRAINING SYSTEM NOW
```

---

### 1. Changed the Serbian Adaptation Task into a Concrete Training Pipeline

Until this point, Serbian adaptation was mainly a research question.

The work now began to turn it into an engineering pipeline.

The required stages became:

```text
Serbian speech data
↓
canonical dataset manifests
↓
audio preparation
↓
IndexTTS preprocessing
↓
GPT training pairs
↓
Serbian tokenizer / configuration
↓
initial training checkpoint
↓
short smoke test
↓
GPU benchmark
↓
full training
```

This was important because the Serbian model could not be treated as one large undefined "fine-tuning" task anymore.

It had to be split into independently testable stages.

---

### 2. ParlaSpeech Became the Main Serbian Training Dataset

ParlaSpeech was selected as the main source for the first Serbian adaptation experiment.

The dataset provides a large amount of Serbian parliamentary speech with transcripts.

The important requirement was not simply:

```text
download ParlaSpeech
```

but:

```text
create one deterministic Serbian training subset
```

so that the same training material could be recreated later on another machine or rented GPU.

The project therefore moved toward a manifest-based dataset design.

---

### 3. Created Canonical Dataset Planning Files

Two important package files became part of the dataset contract:

```text
parlaspeech_sr_split_plan_v3.jsonl
parlaspeech_sr_train_source.jsonl
```

They have different responsibilities.

The split plan defines the selected Serbian material and how it should be used.

The source manifest connects the selected records with the original ParlaSpeech material.

The resulting architecture became:

```text
ParlaSpeech source
+
canonical split plan
+
canonical source manifest
↓
BUILD_DATASET.py
↓
parlaspeech_sr_ready.jsonl
```

This makes the training dataset reproducible instead of depending on an ad-hoc local selection.

---

### 4. Separated Dataset Download from Dataset Construction

A useful architectural decision was made:

```text
PREPARE_PARLASPEECH.sh
```

and:

```text
BUILD_DATASET.py
```

would not perform the same job.

`PREPARE_PARLASPEECH.sh` is responsible for the original ParlaSpeech material.

Its job includes:

```text
download archives
↓
verify downloads
↓
extract source audio
↓
prepare ParlaSpeech/source
```

`BUILD_DATASET.py` has a different responsibility:

```text
read canonical split plan
+
read canonical source manifest
+
use prepared ParlaSpeech audio
↓
construct ready Serbian manifest
```

This separation later became an important project principle:

> Each pipeline stage should verify and own the things that are important to that stage.

---

### 5. Added Download Integrity Checks

Dataset preparation was designed to avoid silently training on incomplete or corrupted downloads.

Downloaded ParlaSpeech archives are checked before extraction.

The preparation logic includes integrity verification using the expected checksums.

The intended chain became:

```text
download
↓
checksum verification
↓
only then extract
```

A corrupted archive therefore should not silently become part of the training dataset.

---

### 6. Made Dataset Construction Restart-Safe

Dataset construction can take a long time.

A failure near the end should not leave a partially written manifest that looks valid.

The output logic was therefore designed around temporary output followed by promotion.

Conceptually:

```text
build temporary manifest
↓
validate build result
↓
atomic promotion
↓
parlaspeech_sr_ready.jsonl
```

The final manifest is only published after the build has completed successfully.

This protects later stages from consuming a half-written dataset description.

---

### 7. Defined the Ready Dataset Contract

The resulting dataset manifest became:

```text
parlaspeech_sr_ready.jsonl
```

This file represents the boundary between:

```text
raw ParlaSpeech preparation
```

and:

```text
IndexTTS training preparation
```

After this point, later scripts should not need to understand how the original ParlaSpeech archives were downloaded or unpacked.

They consume the ready manifest instead.

---

### 8. Prepared Serbian IndexTTS Training Artifacts

The Serbian training package was given a canonical set of model-side artifacts.

These included:

```text
bpe_serbian_13005.model
config_serbian_13005.yaml
gpt_serbian_13005_init.pth
```

Their roles are approximately:

```text
bpe_serbian_13005.model
→ Serbian text/token representation

config_serbian_13005.yaml
→ Serbian training configuration

gpt_serbian_13005_init.pth
→ initial GPT checkpoint for Serbian training
```

The important idea was to stop relying on whatever files happened to exist in the local development folders.

The training package should contain explicit known artifacts.

---

### 9. Serbian Tokenizer Became Part of the Training Contract

The language problem discovered on Day 8 made tokenizer coverage especially important.

The model could not simply be expected to learn Serbian pronunciation while continuing to treat Serbian text through an unsuitable text representation.

Therefore the Serbian tokenizer became a first-class training artifact rather than an incidental dependency.

The target architecture became:

```text
Serbian text
↓
Serbian tokenizer
↓
training pairs
↓
GPT training
```

This directly addressed one of the fundamental differences between:

```text
speaker adaptation
```

and:

```text
language adaptation
```

---

### 10. Prepared a Reproducible Training Repository

The IndexTTS training code was organized as a separate training repository rather than mixed directly with the inference environment.

The live training repository became the source for the future server package.

The important files included:

```text
trainers/train_gpt_v2.py
tools/preprocess_data.py
tools/generate_gpt_pairs.py
pyproject.toml
uv.lock
.python-version
```

This made the training environment reproducible through explicit code and dependency files.

---

### 11. Python 3.11 Became the Current Reference Runtime

The training package was prepared around:

```text
Python 3.11
```

This was treated as the currently verified runtime rather than an eternal hard requirement.

The principle became:

```text
use one known Python version
↓
verify dependencies
↓
verify PyTorch / CUDA
↓
only then run training
```

If another Python version is required later, the system should be migrated and revalidated rather than modified randomly during a server session.

---

### 12. Started Building the Server_Package

Instead of manually copying commands to a rented machine later, a dedicated server package began to be assembled.

The package was designed to contain everything required to reconstruct the training environment.

Important components included:

```text
RUNPOD_SETUP.sh
SERVER_PREFLIGHT.sh
PREPARE_PARLASPEECH.sh
BUILD_DATASET.py
RUN_PREPROCESS.sh
GENERATE_GPT_PAIRS.sh
SMOKE_TEST.sh
BENCHMARK_A40.sh
TRAIN_FULL.sh
RUNPOD_RUNBOOK.md
```

along with:

```text
Serbian tokenizer
Serbian config
initial GPT checkpoint
dataset planning manifests
training repository archive
```

The goal was:

```text
rent empty GPU machine
↓
upload Server_Package
↓
rebuild the same training environment
```

---

### 13. Created RUNPOD_SETUP.sh

`RUNPOD_SETUP.sh` was designed as the first server bootstrap stage.

Its responsibility was to prepare the remote training environment rather than perform the entire training process automatically.

The setup stage included responsibilities such as:

```text
prepare project directories
↓
install / select Python runtime
↓
restore training repository
↓
install dependencies
↓
place canonical model artifacts
↓
prepare environment for later stages
```

The setup script was intentionally separated from the actual training scripts.

A failed environment setup should not accidentally start expensive GPU work.

---

### 14. Added a Staged / Smoke-Oriented Setup Philosophy

The server workflow was deliberately designed not to jump directly into full training.

The intended progression became:

```text
setup
↓
preflight
↓
data preparation
↓
smoke test
↓
benchmark
↓
full training
```

A smoke-oriented mode was considered especially important during initial RunPod deployment.

The principle was:

> First prove that the environment works. Then spend money on a long training run.

---

### 15. Created SERVER_PREFLIGHT.sh

A separate:

```text
SERVER_PREFLIGHT.sh
```

was created to answer the question:

> Is this server actually ready for the pipeline?

The preflight stage checks the environment before dataset processing or training is allowed to continue.

Its responsibilities include checks around:

```text
Python
CUDA
PyTorch
required files
training repository
tokenizer
configuration
initial checkpoint
disk state
```

This prevents failures from appearing only after several expensive stages have already run.

---

### 16. Added Package and File Integrity as a First-Class Requirement

The training system began to treat file identity as important.

The package therefore started using SHA256 verification for critical artifacts.

The idea was:

```text
same filename
≠
proof of same file
```

Instead:

```text
filename
+
SHA256
=
known artifact
```

This became especially important for:

- tokenizer;
- configuration;
- checkpoints;
- training repository archive;
- server scripts.

---

### 17. Created RUN_PREPROCESS.sh

IndexTTS requires preprocessing before GPT training pairs can be produced.

A dedicated stage was created:

```text
RUN_PREPROCESS.sh
```

The intended sequence became:

```text
parlaspeech_sr_ready.jsonl
↓
RUN_PREPROCESS.sh
↓
IndexTTS-compatible processed dataset
```

Again, preprocessing was kept separate from dataset construction.

This makes failures easier to diagnose and allows a successfully built dataset manifest to survive a later preprocessing problem.

---

### 18. Created GENERATE_GPT_PAIRS.sh

After preprocessing, another dedicated stage produces the GPT training/validation manifests.

The output contract became:

```text
gpt_pairs_train.jsonl
gpt_pairs_val.jsonl
```

These files are the direct input for the GPT training stage.

The pipeline therefore became more explicit:

```text
ParlaSpeech
↓
ready manifest
↓
preprocess
↓
GPT pair generation
↓
train / val manifests
↓
trainer
```

---

### 19. Created an End-to-End Smoke Test

Before renting a powerful GPU for full training, a short end-to-end test was needed.

This became:

```text
SMOKE_TEST.sh
```

The purpose was not model quality.

The purpose was to prove that the training chain is technically functional.

The smoke configuration used a deliberately small workload, including approximately:

```text
max samples = 50
max optimizer steps = 20
```

The smoke test was designed to exercise:

```text
dataset input
↓
preprocessing
↓
GPT pair generation
↓
trainer startup
↓
optimizer steps
↓
checkpoint creation
```

---

### 20. Smoke Test Success Was Defined by Artifacts, Not Only Exit Code

A successful command exit alone was considered insufficient.

The smoke test also needed to verify that the expected training artifact was actually created.

The idea became:

```text
trainer returned successfully
+
expected checkpoint exists
+
checkpoint is structurally usable
=
SMOKE TEST SUCCESS
```

This was one of the first places where the project began moving from:

```text
"the command did not crash"
```

to:

```text
"the stage proved its output contract"
```

---

### 21. Introduced the "Each Stage Verifies Its Own Contract" Principle

During the training-package work, an important engineering rule became explicit:

> Every stage should verify the things that are critical for that stage instead of blindly trusting the previous stage.

Examples:

```text
SETUP
→ environment

PREFLIGHT
→ runtime / files / CUDA

PREPARE
→ source dataset integrity

BUILD
→ deterministic dataset manifest

PREPROCESS
→ processed training data

SMOKE
→ short functional training path

BENCHMARK
→ GPU / VRAM / performance

TRAIN_FULL
→ long-running training / resume
```

This principle made the pipeline more robust and also easier to adapt later.

---

### 22. Began Designing the GPU Benchmark Stage

After the smoke test, the next planned gate became:

```text
BENCHMARK_A40.sh
```

The original target GPU was an NVIDIA A40.

However, the benchmark was intentionally being designed around measurements rather than hard dependence on the A40 model name.

Important future measurements included:

```text
optimizer step time
peak VRAM
checkpoint creation
disk usage
```

This would later make it possible to evaluate another NVIDIA GPU if an A40 was unavailable.

---

### 23. A40 Became a Reference Target, Not a Permanent Dependency

The training package began with A40 as the expected rented GPU.

But an important architectural decision was made:

```text
A40 = current reference GPU
```

not:

```text
A40 = hard requirement
```

The correct future procedure would be:

```text
new GPU
↓
preflight
↓
smoke
↓
short benchmark
↓
measure VRAM and speed
↓
decide whether to continue
```

This made the training package more portable.

---

### 24. Started Preparing Full Training as a Separate Stage

The actual long-running training script became:

```text
TRAIN_FULL.sh
```

It was deliberately kept separate from:

```text
SMOKE_TEST.sh
```

and:

```text
BENCHMARK_A40.sh
```

The distinction was important:

```text
SMOKE
=
does the training path work?

BENCHMARK
=
is this GPU suitable?

TRAIN_FULL
=
perform the actual long training
```

At this stage, the full-training path still required deeper review for resume behavior, checkpoints and long-run safety.

That work was intentionally left for the next development stage rather than assumed to be safe.

---

### 25. Created a RunPod Runbook

A dedicated:

```text
RUNPOD_RUNBOOK.md
```

was created to preserve the correct execution order.

The server workflow was documented approximately as:

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

The runbook is important because the package should remain usable even after the exact development commands are forgotten.

---

### 26. Separated Working Scripts from Development Experiments

The package began to act as the canonical server-side interface.

This meant a distinction between:

```text
development folders
```

and:

```text
Server_Package
```

The package should contain only the files actually required for reproducible deployment.

Temporary experiments, local caches and unrelated development artifacts should not be treated as server inputs.

---

### 27. Began Treating the Training Repository as a Versioned Artifact

The live IndexTTS training repository was prepared for packaging into:

```text
index-tts-2-train.zip
```

This archive was intended to become the canonical source restored by `RUNPOD_SETUP.sh`.

The reason for using an archive rather than cloning an uncontrolled future repository state was reproducibility.

The server should receive:

```text
the exact training code we tested
```

rather than:

```text
whatever happens to be current upstream when the GPU is rented
```

---

### 28. Server Preparation Became Independent of GPU Budget

This stage demonstrated an important practical advantage.

Although the actual training GPU could not yet be rented, almost the entire infrastructure could be prepared without paying for GPU time.

Work that could be completed locally included:

```text
dataset architecture
training manifests
tokenizer/config/checkpoint preparation
training scripts
server bootstrap
preflight
smoke-test design
benchmark design
full-training script
runbook
integrity checks
```

This significantly reduced the amount of expensive debugging that would later need to happen on RunPod.

---

### 💡 Main Result of the Day

The Serbian adaptation project moved from:

```text
"we probably need to fine-tune IndexTTS"
```

to:

```text
a concrete reproducible training pipeline
```

The system now had clearly separated stages:

```text
SETUP
↓
PREFLIGHT
↓
DATASET PREPARATION
↓
DATASET BUILD
↓
PREPROCESS
↓
GPT PAIRS
↓
SMOKE
↓
BENCHMARK
↓
FULL TRAINING
```

The project was no longer waiting passively for GPU budget.

Instead, the future rented GPU was being treated as the final execution environment for a package that should already be prepared and tested.

---

### ✅ Status at the End of Day 9

#### Serbian Adaptation Direction

```text
ACTIVE
```

The problem had moved from general research into concrete training preparation.

---

#### ParlaSpeech

```text
SELECTED AS PRIMARY INITIAL DATASET
```

Canonical dataset planning files prepared.

---

#### Dataset Pipeline

```text
STRUCTURED
```

Main stages:

```text
PREPARE_PARLASPEECH
↓
BUILD_DATASET
↓
RUN_PREPROCESS
↓
GENERATE_GPT_PAIRS
```

---

#### Serbian Training Artifacts

```text
PREPARED
```

Including:

```text
bpe_serbian_13005.model
config_serbian_13005.yaml
gpt_serbian_13005_init.pth
```

---

#### Server_Package

```text
IN ACTIVE DEVELOPMENT
```

The package architecture and main server scripts were established.

---

#### SERVER_PREFLIGHT

```text
CREATED
```

Designed to validate the remote environment before expensive work.

---

#### SMOKE_TEST

```text
CREATED / BEING VALIDATED
```

Designed to prove the complete short training path.

---

#### BENCHMARK_A40

```text
PLANNED / UNDER DEVELOPMENT
```

Intended to measure:

```text
VRAM
step time
checkpoint behavior
disk usage
```

before full training.

---

#### TRAIN_FULL

```text
CREATED
REQUIRES DEEP SAFETY REVIEW
```

Important remaining questions included:

```text
resume after interruption
checkpoint safety
logging
epochs / steps
disk safety
final success criteria
```

---

#### RunPod

```text
NOT STARTED
```

Reason:

```text
budget
```

No paid GPU training was performed.

---

### 🔥 Day 9 Milestone

The project gained a new engineering layer.

Before:

```text
Serbian adaptation
=
research problem
```

After:

```text
Serbian adaptation
=
dataset
+
training artifacts
+
server package
+
staged validation
+
future GPU execution
```

The most important architectural principle established during this stage was:

```text
each stage verifies
what is important
for that stage
```

This principle would guide the deeper safety work on benchmark and full training.

---

### 🔜 Next Step

Before renting the training GPU:

- finish validating `SERVER_PREFLIGHT.sh`;
- fully verify the ParlaSpeech → dataset-build path;
- complete the end-to-end `SMOKE_TEST.sh`;
- strengthen and audit `BENCHMARK_A40.sh`;
- deeply review `TRAIN_FULL.sh`;
- verify resume behavior after interruption;
- protect long-running checkpoints;
- verify disk safety;
- finalize the training repository archive;
- update package SHA256 checks;
- perform a complete final package audit.

Only after these stages are green:

```text
rent GPU
↓
upload Server_Package
↓
RUNPOD_SETUP
↓
SERVER_PREFLIGHT
↓
SMOKE
↓
BENCHMARK
↓
TRAIN_FULL
```

---

### 🔗 Related

- Day 8
- Serbian Adaptation
- Serbian Model
- Serbian Datasets
- ParlaSpeech
- IndexTTS-2
- TED-TTS
- Serbian Tokenizer
- Fine-tuning
- GPU Rental
- RunPod
- Server_Package
- RUNPOD_SETUP
- SERVER_PREFLIGHT
- BUILD_DATASET
- SMOKE_TEST
- BENCHMARK_A40
- TRAIN_FULL
- RunPod Runbook
