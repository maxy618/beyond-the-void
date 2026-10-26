# Audio direction — Beyond the Void

Status: architecture and direction are binding. Asset quality is classified per file as
**draft** or **final**. The agent cannot hear rendered audio; acoustic approval is a human gate.

## Identity

Quiet science fiction: isolation, discovery, scale, danger, technological wonder. Restrained and
textural rather than orchestral bombast. Sound supports the pixel art and the narrative tone:
wind, water, hull metal, distant radio, low drones, fragile melodic motifs.

Reference palette (not copies): bowed metal, tape hiss, filtered noise, glass bells, sub drones,
short plucked motifs, mechanical servo layers, radio-band voice processing.

## Buses

`Master → Music, SFX, Ambience, Dialogue, UI, Ship, Combat`

- Master: limiter, overall volume, mute.
- Music: stems, bar-quantized crossfades, ducking under dialogue and critical SFX.
- Ambience: biome loops, weather, fauna calls, spatial emitters.
- SFX: player tools, footsteps, interactions; concurrency-limited.
- Dialogue: radio/comms treatment, no voice acting claimed.
- UI: clicks, confirms, errors; never spatial.
- Ship: engine layers, thrust, entry turbulence, warnings.
- Combat: weapons, impacts, shield, explosions; priority over exploration.

## Music states

TITLE, CRASH, SURVIVAL, EXPLORE_CALM, DISCOVERY, CRAFT, RELAY, TAKEOFF, SPACE, APPROACH, ENTRY,
LANDING, COMBAT, DANGER, BLACK_HOLE, SETTLEMENT, REVELATION, PAUSE.

Priority: COMBAT > DANGER > ENTRY > DISCOVERY > RELAY/TAKEOFF/LANDING > EXPLORE/SETTLEMENT >
TITLE/PAUSE. Transitions are debounced, bar-quantized, and must not restart a track that is
already correct. Pause freezes/suspends cleanly; save/load restores the correct state.

## Sound-event registry

`content/audio/events.json` fields: `id`, `asset`, `bus`, `priority`, `max_instances`,
`cooldown_ms`, `pitch_range`, `gain_db`, `attenuation`, `loop`, `stop_condition`.

Every meaningful action has either a registered event or a documented reason for silence.

Required coverage: footsteps by material, sprint/exhaustion, jetpack ignition/thrust/empty/
touchdown, suit alerts; tool switch, scan charge/pulse/success/fail, mining loop and material
impacts, depletion; observation/calming; UI/menu/inventory/craft/repair/build/market/dialogue/
quest/save; ship ignition/idle/thrust/brake/turn/boost/takeoff/landing/entry/warnings; combat
weapons/impacts/shields/explosions; black-hole ambience; biome ambience; fauna calls; radio/comms;
Kasa motif.

## Spatial rules

- World emitters: `AudioStreamPlayer2D` with distance attenuation and per-type caps.
- Music/UI: non-positional `AudioStreamPlayer`.
- Fauna calls are coordinated (no overlapping wall of calls), capped per species and per region.
- Loops start and stop with real state; no leaks across pause, scene change or save.

## Technical targets

- Music/ambience: OGG, 44.1 kHz, seamless loop points.
- Short SFX: WAV, 44.1 kHz, mono or stereo as appropriate, normalized headroom.
- No clipping; true peak ≤ −1 dBFS on the master; loudness consistency across SFX families.
- Voice cap per bus; no more than N simultaneous instances of the same event.

## Verification

Technical (agent): `AudioEffectCapture` harness measures bus RMS/peaks, silence, active event
IDs, music state, voice counts and loop continuity. Deterministic playback checks confirm every
registered event loads and plays.

Acoustic (human): listening review of music loop quality, transition musicality, mix balance,
fatigue, spatial believability and Android speaker/headphone behaviour. Until performed, the
report says **BLOCKED / NOT TESTED** and never "sounds good".

## Provenance and classification

`assets/audio/README.md` lists every file with source (original synthesis/design), tool or
process, licence, duration, loop points, sample rate and normalization. Each asset is marked
`draft` or `final`. Draft assets below the bar get a named production task (composer/sound
designer, same filenames and buses), not a quality claim.
