# DubLab SRB — Development Journal

This journal documents the development of DubLab SRB: experiments, technical decisions, failed approaches, discoveries and results.

The purpose of keeping this journal is to preserve the real development history of the project and make the research process reproducible.

---

## Development Log

- Day 1 — First TTS experiments and Pinokio
- Day 2 — Serbian F5-TTS and model testing
- Day 3 — Datasets, ElevenLabs API and n8n
- Day 4 — Fish Audio S2 Pro and TTS comparison

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
