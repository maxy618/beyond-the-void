# Beyond the Void — Overhaul Implementation Plan

**Authority and precedence.** This plan executes the Stage 0–9 brief plus every review requirement: dynamic camera, pixel rendering, cinematic scale, adaptive audio, procedural universe, procedural ecology, generated art quality, and continuous GitHub workflow. `docs/beyond_the_void_spec/` is authoritative reference and is never deleted or rewritten. On approval, **Stage 0 saves this document verbatim to `.opencode/plans/beyond-the-void-overhaul.md`** so later context compaction cannot weaken it, and Build Mode executes that file.

**Ambition split (explicit, non-negotiable in reporting).**

- **Milestone 1 — Playable Overhaul.** Every engine, control, camera, rendering, audio, UI, save, generation and verification system below. Vela is the authored showcase; the procedural universe and ecology engines are complete and landable on generated planets; the black hole has a hands-on showcase; audio architecture is complete with original draft material and honest listening status; Android emulator evidence exists.
- **Milestone 2 — Full Game Content.** Five curated planets plus a broad procedural universe, the cross-planet progression chain, the black-hole narrative encounter, full species/structure/ship rosters, and completed audio content.

Milestone 1 is a polished first planet and a working universe engine, **not** the finished game. Reports must say so. Implementation continues into Milestone 2 in dependency order; if something blocks it, the exact missing planets, objectives, assets or validations are listed instead of calling the game complete.

---

## 1. Verified baseline (fresh, this session)

| Item | State |
|---|---|
| Repo | `D:\beyond-the-void`, branch `main`, HEAD `6709f22` (`Add Godot gitignore`) |
| Remote | `https://github.com/maxy618/beyond-the-void.git`, `git ls-remote` works |
| Credentials | helper `manager`, user `maxy618`; `gh` CLI **not installed** |
| Working tree | `M .gitignore`, `M project.godot`, untracked `README.md`, `build/`, `content/`, `export_presets.cfg`, `opencode.json`, `scenes/`, `scripts/`, `tests/`, `tools/`, `.serena/` |
| CI | no `.github/` directory |
| Historical tests | 68 domain, 52 UI checks / 16 shots, content OK + 1 allowed dialogue-loop warning, 500/500 seeds |
| Android | `build/android/BeyondTheVoid-debug.apk`, 58,777,638 B, SHA256 `AB38B301…01A3EF`, verified on API 37 emulator earlier |
| Godot | 4.7.2 console at `C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe` |
| MCP | server installed; project has no `addons/`; connection refused at `ws://127.0.0.1:6550` |
| Presentation | one `Control` scene, all-code UI, `_draw` vector world, permanent 252 px dock, one joystick, no camera node, no collision, no ship flight, instant chart teleport |

Historical numbers are comparison points only. Stage 0 re-runs everything cold and records fresh evidence.

---

## 2. Hard constraints

1. Preserve the repository and `docs/beyond_the_void_spec/`.
2. Preserve domain services and content unless a verified replacement exists; every retirement is listed with its replacement and evidence.
3. No feature is called working until it changed the running game under real input and was observed.
4. Every result is labelled **PASS** (evidence), **FAIL** (reproduction steps), **BLOCKED** (missing prerequisite), or **NOT TESTED**.
5. No commits of secrets, keystores, APKs, `.godot/`, import caches or machine-specific paths.
6. No software installation or system-wide change without explicit permission (this includes `gh`).
7. No force-push, no history rewrite, no silent push failure.
8. Generated content must be deterministic and reproducible from seed + generator version; saves store deltas and stable IDs only.
9. Finished world content may not be primitive geometry standing in for art. Procedural composition is allowed; invented silhouettes are not.
10. The agent cannot hear audio; acoustic quality is never claimed. Technical audio evidence and human listening status are reported separately.

---

## 3. Architecture

### 3.1 Layering

- **Domain (preserved):** `scripts/core`, `scripts/systems`, `content/`, save/recovery, quests, ecology, economy, building, ship, inventory, crafting, market, dialogue.
- **Presentation (rebuilt):** `Node2D` surface world, `SpaceWorld`, `CharacterBody2D` player, `CameraDirector` owning one `Camera2D`, `CanvasLayer` HUD, world rendered through a `SubViewport`.
- **Facade (stable):** `BtvGameScreen` keeps `session`, panel routing, pause and save semantics so `app.gd` and tests keep a stable entry point while internals are replaced.
- **Generation (new):** `UniverseGen`, `PlanetProfile`, `BiomeGen`, `ChunkGen`, `FloraGen`, `FaunaGen`, `StructureGen`, `ShipGen`, `EquipmentGen`, `MaterialGen`, `NameGen`, all pure static/deterministic.

### 3.2 Determinism contract

- FNV-1a stream seeds exactly like existing `WorldGen.stream_seed`, extended to 64-bit for large ID spaces.
- Every generator is a pure function of `(seed, stable indices, generator_version)`. No global RNG, no time, no OS, no dictionary iteration order in output. Keys are sorted before hashing.
- **Stable IDs come from indices, never from hashes:** `planet.<system_index>.<planet_index>`, `species.<planet_id>.flora.<biome_slot>.<slot>`, `struct.<planet_id>.<chunk_x>.<chunk_y>.<slot>`, `ship.<system_index>.<slot>`, `equip.<tier>.<family>.<variant>`.
- Each generator has its own `GENERATOR_VERSION`. Changing it invalidates regenerable content but never player-owned deltas, which are keyed by stable IDs.
- Golden fixtures in `tests/fixtures/gen_golden.json` pin hashes for a fixed set of seeds. A version bump requires an explicit, reviewed fixture update.
- Float math is presentation-only; IDs, names, resource tables and ecology graphs use integer streams so platform differences cannot rename a planet.

### 3.3 Cylindrical planet coordinates

- Longitude `x` is an **unbounded float**; all sampling uses `fposmod(x, C)`; physics/camera use continuous `x`, so `C → 0` never jumps.
- Latitude `y` is bounded `[0, H]`; polar bands end in impassable ridges and never wrap.
- Chunk columns wrap modulo `C / 512`; rows clamp. Ground art is continuous world-space noise, so chunk seams are invisible. Neighbour columns render at ±`C` offsets; props may overhang chunk edges.
- A full circuit is detected when `fposmod(x - start_x, C) < 512` **and** the route landmark is reached. Longitude is shown in degrees.
- Profile ranges: circumference 3072–6144, latitude height 1536–3072, chunk 512. Curated: Vela 5120×2560, Brine 4608×2048, Cinder 5632×2560, Tallow 4096×2048, Threshold 3072×1536.

### 3.4 Save schema 3

Adds: per-planet position/longitude, prologue stage, ship state (fuel/energy/altitude/site/damage), unlocks, visited chunks, discovered landmarks/species/structures, depletion and regrowth, planet objectives, health/shield, audio/control/pixel settings, generator versions, curated-name cache.

Properties: atomic write + backup slot, schema 2 migration with fixtures, corrupt-save fallback that never deletes the last good slot, only deltas stored (never generated geometry), unknown-ID tolerance.

### 3.5 Flight and combat

- One `flight_model.gd` drives free space flight and surface flight: thrust, rotate, brake, inertia, energy/fuel, altitude, touchdown envelope.
- Space has real planet positions and distances; target selection never teleports.
- Combat is a real but contained system: health/shield, rogue survey drones and aggressive fauna, projectiles, hit/impact feedback, death → respawn at last camp/ship with no save loss.

### 3.6 Evidence hierarchy

Godot MCP hands-on play is primary. ADB is the Android proof. Scripted playtests are supplemental. Unit tests prove rules, never that a player-facing interaction feels or renders correctly.

---

## 4. Procedural universe

### 4.1 Model

- **Infinite sector grid**; a sector generates deterministically on demand from `(sector_x, sector_y)`.
- **Starting sector** `(0,0)`: 48 systems, ~180 bodies, 2 anomalies, 1 black hole, asteroid belts, derelict lanes.
- **System:** star class (O/B/A/F/G/K/M, neutron, binary, black hole), 1–6 planets, 0–3 moons each, belt, orbital radii/eccentricity/phase, hazard level, faction/culture tag, market presence.
- **Body classes:** rocky, ocean, ice, desert, toxic, volcanic, gas giant, moon, artificial. Gas giants and stars are not landable (upper-atmosphere skimming only); every solid body is landable in principle, gated by suit rating and scan data.
- **Curated planets are pinned**, not special-cased in engine code: fixed system index + planet index + authored overrides (biome weights, landmarks, quests, species pools, art direction, audio palette, objectives). Vela, Brine, Cinder, Tallow, Threshold Anchor always exist at stable coordinates; the generator fills everything around them.
- **Scale:** the game must support thousands of planets; QA deeply verifies the curated five plus at least 12 procedurally generated landable planets, while automated tests cover ≥1,000 seeds.

### 4.2 Derived planet profile

From radius, mass, temperature, gravity, atmosphere, hydrosphere, geology and seed:

- surface circumference/height, gravity multiplier, day length, weather table;
- biome weights and adjacency rules (coastal, mist forest, crystal ridge, kelp flat, ash shore, glacier, vent field, salt pan, station deck, …);
- resource table (ore, crystal, fiber, gas, salvage) tied to geology and biology;
- hazard table (radiation, thermal, toxic spores, storms, tides, traffic);
- structure/ruin density and culture style;
- species richness and ecology archetypes;
- landing-site quality and orbital scan requirements;
- palette (base, accent, emissive) harmonized with star light and atmosphere.

### 4.3 Naming and discovery

- Seeded syllable grammar with per-culture tables, system-level dedupe, generated binomial names for procedural species.
- Discovery tiers: long-range (name/class), proximity (resources/biomes), orbital scan (sites/hazards/species preview), surface survey (points of interest, ecology entries).
- Discovered names and scan results persist; generator bumps must not rename visited places.

### 4.4 Navigation and streaming

- Real space flight with fuel/energy, scan gates and entry requirements; no chart teleport.
- Planet surfaces generate only on approach/landing; summaries are LRU-cached with a hard cap (256) so a 1,000-planet tour cannot exhaust memory.
- Chunk streaming: 3×3 resident window (LRU), 10,000-chunk churn test, no node leak, no void, bounded generation time (< 8 ms/chunk target).

### 4.5 Universe tests

≥1,000 planet seeds × 3 generator versions of key fields; reproducibility hashes; biome/resource/hazard distribution bounds; name collision rate; stable IDs across runs; save round-trip for 100 sampled planets; landing-site validity; orbit/entry math; memory cap under 10,000-chunk churn.

---

## 5. Procedural ecology

### 5.1 Genome model

**Flora genome:** growth form (reed, bell, mat, frond, canopy, cactus, fungus, vine, bulb, crystal), branching rule (none/alternate/whorl/dichotomous), height class, frond/leaf shape and count, glow organs, pattern, sway parameters, harvest part, toxicity, rarity.

**Fauna genome:** body plan (quadruped, hexapod, serpent, drifter, crawler, avian, jelly, swarm), size class, limb count/length, wing/fin type, shell/armor, head shape, eye count, tail, pattern, gait, diet, temperament, activity cycle, social behavior, call type.

Genomes are derived from planet seed + biome + ecological niche, with constrained ranges so silhouettes stay coherent.

### 5.2 Authored parts, generated bodies

- A hand-authored pixel **part library** (`assets/art_src/creatures/parts/`) supplies heads, torsos, limbs, wings, shells, fronds, bulbs and pattern stamps at defined mount points and 2–3 size classes.
- Composition rules reject impossible assemblies (wing mount without torso socket, limb count over body-plan max, canopy taller than its height class), enforce silhouette padding and ground contact, apply the planet palette, 1 px outline, top-left light, no anti-aliasing.
- Frames are composed for idle, locomotion, alert/attack, and death/decay where relevant; animation is parameterized by gait and body plan, then baked into atlas pages keyed by stable species ID.
- **This is the quality rule:** the generator assembles designed pixel clusters; it does not invent silhouettes from primitives. If a composition fails the quality gate, it is rejected and regenerated with a different slot, not shipped.

### 5.3 Ecology simulation

- Per-biome food web: producers, herbivores, predators, decomposers, scavengers, with population caps and spawn tables derived from the web.
- Behavior templates: grazer, skittish, stalker, ambush, drifter, swarm, territorial; simple state machines with perception, flee/fight, patrol, feeding, rest.
- Fauna calls, flock spacing, nocturnal activity and weather reactions drive both ambience and gameplay.
- Resource yields derive from genome parts (fiber from fronds, crystal from bell organs, spore pods from mats), with generated ethical-harvest notes.

### 5.4 Persistence and discovery

- Codex entries: silhouette + traits on scan, full entry on observation, sample grants resource and ethics note.
- Persisted: discovered species, observation counts, sampled nodes, population deltas, regrowth timers, named variants.
- Curated species keep existing IDs (`species.flora.saltreed`) and appear only in curated pools; procedural species use stable generated IDs and never overwrite curated entries.

### 5.5 Ecology tests

≥2,000 flora and ≥2,000 fauna genomes across 1,000 planets: reproducibility, palette legality, mount validity, silhouette uniqueness ≥85% within the same biome/size class, animation frame validity, population caps, food-web completeness (every predator has prey, every producer has a habitat), save/restore of discoveries and depletion.

---

## 6. Procedural structures, ruins, ships, equipment, materials

### 6.1 Structures and ruins

- Footprint grammar 3×3…12×12 tiles; rooms from authored tilesets per culture (settlement, research, industrial, shrine, derelict); corridors connect entrance to rooms; roof styles; decay stages (intact, weathered, collapsed, overgrown).
- Placement rules: flat-enough ground, not in water/cliffs, not overlapping landmarks or the route, entrance facing the path, spawn-safe perimeter.
- Validation before acceptance: flood-fill reachability from entrance to every room, no orphan rooms, doors on walls, collision from tile occupancy, navigation graph for NPCs/fauna, loot/terminal anchors reachable.
- Interior/exterior transitions for boardable wrecks; loot, terminals, hazards, ambience and audio hooks.
- Generated structures must be enterable, exitable, and never trap the player.

### 6.2 Ships and equipment

- Ship grammar: hull class + segment modules (cockpit, cargo, engines, wings, sensors, damage state), silhouette rules, thruster anchors, damage/repair visual states; used for the player ship, derelicts and traffic.
- Equipment: tier + family + material → stat budget with clamps; generated names; icons composed from authored part icons; no stat outside designed bands.
- Materials: derived from geology/biology; properties (hardness, conductivity, density, toxicity, heat) map to crafting tags and market value.

### 6.3 Validation

Reachability, collision, navigation, anchor validity, overlap, spawn safety, silhouette bounds, palette legality, and deterministic rebuild. Structures generate ≥1,000 samples in tests; ships/equipment ≥500; every accepted sample must pass navigation and collision assertions.

---

## 7. Generated art: quality gates

- **Source of truth:** `assets/art_src/` pixel maps (indexed palettes, explicit clusters). `tools/build_art.gd` validates, composes, packs atlases and writes `.import` metadata; it never invents silhouettes.
- **Hero assets are individually designed:** player suit (4 directions × idle/walk/jetpack/mine/combat), multitool, player ship (flight/damaged/wrecked/thruster states), Kasa, market stall, relay (3 states), wreckage, 12 curated flora (2 states), 12 curated fauna (animated), 6 minerals, 4 buildings (2 states), 5 curated planets, black hole, item/HUD icons.
- **Generated assets** use the authored part library with strict composition rules; accepted output is baked and committed so builds are reproducible.
- **Per-asset acceptance:** designed clusters, biome-coherent palette (≤12 colors + outline), readable silhouette at gameplay scale, intentional animation, correct pivot/shadow/depth, no stray pixels, no primitive stand-ins.
- **Automated audits:** palette count, outline presence, transparent padding, frame-to-frame motion delta, silhouette hash uniqueness, forbidden primitives, nearest filtering, integer scaling.
- **Visual audits:** contact sheets at 1×/2×/3× and in-game captures at 720×1280 and 1080×2400; ≥30 world regions plus species/structure/planet lineups; each reviewed with a written verdict and named defects.
- **Honesty:** anything below the bar is labelled stylized prototype with a defined artist-production pass, never "final".

---

## 8. Camera director

`scripts/world/camera_director.gd` owns one `Camera2D` and a mode state machine. Gameplay code never sets zoom. Each mode declares framing target, zoom range, look-ahead, dead zone, critically damped smoothing, bounds policy, transition blend, shake gain, exit conditions.

| Mode | Purpose | Framing |
|---|---|---|
| `ON_FOOT` | Player + nearby targets readable | close, small aim look-ahead |
| `ON_FOOT_SPRINT` | Restrained pullback for speed | ~8% wider, quick settle |
| `ON_FOOT_AIM` | Target and aim line readable | push toward aim point |
| `JETPACK` | Reveal surroundings during ascent | widen with altitude, narrow on landing |
| `SURFACE_FLIGHT_LOW` | Ship + ground detail | medium, velocity lead |
| `SURFACE_FLIGHT_HIGH` | Larger terrain area | wide, altitude-aware |
| `SPACE_CRUISE` | Ship + travel vector | medium-wide, velocity lead |
| `SPACE_COMBAT` | Player, aim, threats, projectiles | widen with threat spread, restrained shake |
| `ORBIT_SCAN` | Planet + ship + scan UI | planet fills a deliberate screen fraction |
| `ENTRY` | Atmospheric scale and descent | high framing, turbulence shake |
| `LANDING` | Touchdown | smooth narrow to walking view |
| `EVENT_SCALE` | Celestial significance | size/distance-derived coverage |
| `CINEMATIC` | Crash and story beats | authored dolly, skippable |

- **Smoothing:** critically damped springs for position and zoom; dead zone before follow; clamped velocity look-ahead; no oscillation or zoom steps.
- **Large-body formula:** `desired_screen_fraction = f(radius, distance)`; `world_view_height = diameter / desired_screen_fraction`; `zoom = viewport_height / world_view_height`, clamped by mode and bounds. Used for planets and the black hole instead of magic constants.
- **Black hole:** dark core, luminous accretion disk, layered lensing/distortion shader, warped starfield, particles, gravitational audio; `EVENT_SCALE` composes horizon + disk + nearby bodies from long range to close range. Full narrative encounter is Milestone 2; the showcased Threshold Anomaly is Milestone 1.
- **Shake:** trauma model (`offset = trauma² · max`), priority sources, decay; intensity setting and 0% / reduced motion; no shake from ordinary walking.
- **Aim independence:** aim direction is computed in world space from input and current transform before smoothing; zoom or snapping never biases targeting.
- **Pixel safety:** camera render position snaps to the world pixel grid after smoothing; aim math stays unsnapped.
- **Constraints:** player always readable, no speck-sized player, no empty void beyond playable surface, targets not occluded by framing.

**Camera verification matrix (MCP primary):** walk; sprint; move+aim; jetpack up/down; low/high surface flight; space accelerate/brake/turn; approach/orbit; entry/landing; combat with movers and projectiles; black hole long→close; impact/gravity shake plus reduced-shake; four quality presets; four resolutions. Measure mode, zoom, position, shake via runtime state; record frame times.

---

## 9. Pixel rendering pipeline

- **Separation:** world inside a `SubViewport` at reduced internal resolution, displayed through integer-scaled `SubViewportContainer` with nearest filtering. HUD/text/panels/touch live on a native-resolution `CanvasLayer` and are never downscaled.
- **Pixel density:** Auto / 1× / 2× / 3× world-pixel size; phone default ≈2× (360×640 internal for 720×1280); desktop integer fit. Field of view is preserved; only pixel size changes.
- **Sharpness:** `TEXTURE_FILTER_NEAREST`, pixel snapping, `snap_2d_transforms_to_pixel`, integer scaling, letterbox/pillarbox where needed.
- **Invariants:** world coordinates, collision, targeting, touch mapping and physics are independent of render scale; resizing or density change must not alter gameplay or effective touch sizes.
- **Quality presets (measurable):** Low — coarse density, no glow, few lights, low particles, no haze, 1 parallax layer. Medium — default density, additive halos, more particles, 2 layers. High — finer density, real glow, dynamic lights, shadows, 3 layers, haze. Ultra — finest density, richer glow, max lights/particles, full weather/reflections.
- **Adaptive resolution:** smoothed frame-time window, downgrade after sustained over-budget with cooldown, restore only after sustained headroom, hysteresis prevents flicker, UI and logic untouched; debug HUD shows scale and reason. Test forced pressure → downgrade → recovery with no oscillation.
- **Test captures:** same location at all presets and all four sizes; inspect blur, pixel-grid consistency, UI scaling, player readability, camera jitter.

**VFX and material stack (all configurable, persisted, quality-scaled):**

- **No fake RTX claim:** hardware ray tracing is not promised on mobile. "RTX-style" means convincing screen-space and 2D approximations: planar water reflections, Fresnel and specular glints, refraction-like UV distortion, bloom, light shafts and wet-surface response. Settings and reports use those words, never "ray traced".
- **Bloom / glow:** threshold + multi-scale blur, additive; crystals, visors, engines, bioluminescence, relay lights and UI accents. Strength control; UI is never blurred; no full-screen haze pass.
- **Light shafts:** screen-space god rays masked by occluders; canopy, dust, water surface, station interiors and the black-hole showcase. Intensity and quality control; shafts must move with the light source, not sit as a static overlay.
- **Reflections:** planar reflection for water, mirrored/screen-space reflections for wet ground and polished metal, Fresnel rim and sharp specular glints on glass, crystal and hull plate. No screen-space ray marching on mobile; each reflection is a real render pass or a designed sprite/mirror pass, not a painted gradient.
- **Glass:** tinted transparency, edge highlight, scratches, condensation, interior haze and refraction offset on panes and canopies; readable at 1× density; no milky alpha slabs.
- **Water:** two seamless animation phases, foam, depth tint, caustics, shoreline ripples, interaction ripples from player/ship, refraction; quality tiers must visibly differ; no flat opaque blue.
- **Motion blur:** camera/velocity based, optional, **off by default on mobile**, forced off by reduced motion; strength control; must never smear the pixel grid, UI, reticle or text. The world may blur; gameplay information may not.
- **Particles:** dust, spores, sparks, rain, sandstorm, ash, snow, bubbles, engine exhaust and combat impacts; wind-driven; density scaled by preset and by weather intensity; no particle count that hides the player or collisions.
- **Weather:** sandstorms, rain, mist, ashfall and ember wind with visibility and movement effects; intensity setting; weather must read on screen and in audio, not only in a status label.
- **Post:** per-biome colour grade only; no indiscriminate filter stack, no permanent vignette/chromatic-aberration wash that muddies pixel art. Every effect must be individually switchable.

**VFX settings and budgets:**

- Settings expose Bloom, Light shafts, Reflections, Water quality, Motion blur, Particle density, Weather intensity and Reduce motion; each has an on/off or Low/Medium/High/Ultra value, a sane mobile default, live preview, reset, and persistence in the save schema.
- Every effect has a measured frame-time cost at 720×1280 and 1080×2400; adaptive resolution reacts to the total; no effect may obscure gameplay, UI, reticle or the pixel grid.
- Acceptance: the same location captured with each effect on and off and at every preset; visible, measurable differences; settings survive restart and Continue; reduced motion disables shake and motion blur; every capture is reviewed by the visual QA artist with named defects and fixes.

---

## 10. Audio

**Identity:** atmospheric sci-fi isolation, discovery, scale, danger, technological wonder; restrained, textural, spatially coherent.

**Architecture:**

- `AudioManager` autoload with buses `Master`, `Music`, `SFX`, `Ambience`, `Dialogue`, `UI`, `Ship`, `Combat`; persisted volumes, mute/reset, ducking, concurrency caps, priorities, pooling, fades, cleanup.
- `MusicDirector` states: TITLE, CRASH, SURVIVAL, EXPLORE_CALM, DISCOVERY, CRAFT, RELAY, TAKEOFF, SPACE, APPROACH, ENTRY, LANDING, COMBAT, DANGER, BLACK_HOLE, SETTLEMENT, REVELATION, PAUSE. Layered stems, bar-quantized crossfades, event accents, priority rules (combat > danger > entry > discovery > exploration), debounce, pause/resume, save/load coherence.
- `content/audio/events.json`: id, asset, bus, priority, max instances, cooldown, pitch/gain variation, 2D attenuation, loop, stop condition. Every meaningful action has a designed sound or a documented silent reason.
- **Coverage:** footsteps by material, sprint/exhaustion, jetpack ignition/thrust/empty/touchdown, suit alerts; tool switch, scan charge/pulse/success/fail, mining loop matched to beam state and material, depletion; observation/calming; UI/menu/inventory/craft/repair/build/market/dialogue/quest/save; ship ignition/idle/thrust/brake/turn/boost/takeoff/landing/entry turbulence/warnings; combat weapons/impacts/shields/explosions; black-hole ambience; biome ambience and fauna calls with per-species caps; radio/comms and Kasa motif.
- **Spatial:** `AudioStreamPlayer2D` for world emitters, `AudioStreamPlayer` for music/UI; loops start/stop with real state and never leak across scenes, pause or save.
- **Narrative:** no voice acting claimed; text at player pace, character motifs, comm noise, radio treatment.
- **Android:** OGG for music/ambience, WAV for short SFX, voice caps, focus-loss/pause/resume handling, no middleware dependency.

**Asset honesty:** original synthesized/designed material with documented provenance, classified per asset as **draft** or **final**. Technical verification uses an `AudioEffectCapture` harness (bus RMS/peaks, silence, active event IDs, music state, voice counts, loop continuity) plus deterministic playback checks. Listening quality is a separate gate: **BLOCKED/NOT TESTED** until a human hears it. Draft material below the bar gets a named audio-production task, not a quality claim.

**Audio matrix:** fresh game/crash; walk/sprint/stop; jetpack ignition/thrust/depletion/landing; scan success/fail; mining loop/gather/depletion; inventory/craft/repair/dialogue; ship ignition/move/brake/takeoff/landing; orbit/entry/planet transitions; every biome; combat and return; black-hole approach; pause/resume/save/continue/force-stop; rapid mode switching; per-category mute/restore/persistence.

---

## 11. UI and UX

- New theme: squared sci-fi frames, corner brackets, scanlines, pixel font, cyan/amber palette, consistent icon set; ≥48 dp (56 dp preferred) targets, ≥12 px spacing, safe areas, text scaling, left-handed mirroring, reduced motion.
- Title: layered animated pixel landscape, logo plate, save-slot card (location, time, credits), New/Continue/Settings/Quit.
- HUD: slim status (location, longitude, time, stamina, energy, credits, health/shield), objective chip, contextual action card, two sticks, separate Use/Interact/Sprint/Jetpack/Tool/Menu; permanent dock removed.
- Menu deck: Pack, Craft, Ship, Log, Map, Base, Market (gated), Settings; restyled sheets; map with fog, landmarks, player, longitude; item icons in lists.
- Every displayed control works or explains its unavailable reason. No decorative buttons.
- Four required sizes: 360×640, 720×1280, 1080×2400, desktop widescreen; each screen captured and reviewed for clipping, overlap, tiny targets, scale, contrast and confusion.

---

## 12. GitHub as an active platform

**Facts:** remote is reachable, `gh` is not installed, credential helper `manager` exists. No installation without permission.

**Branching and commits**

- Commit the verified baseline checkpoint on `main` (Stage 0).
- Create `overhaul/procedural-universe` from it; all overhaul work happens there.
- Conventional commits; one commit series per stage gate; push after each gate.
- `.gitignore` gains `build/android/*.apk`, `build/cache/`, `*.keystore`, `addons/godot_mcp/`; `.godot/` already ignored.
- Never commit secrets, tokens, APKs, import caches or machine paths. Never force-push.

**Issues and PR**

- One issue per stage (0–9) with acceptance criteria copied from this plan, plus issues for discovered defects.
- Draft PR `overhaul/procedural-universe → main` opened in Stage 0 and kept updated with gate evidence, screenshots and honest status.
- Because `gh` is absent, issues/PR use the GitHub web UI or REST API with a user-supplied token supplied outside the repo. If neither is available, local commits and a ready branch are produced and the push/PR step is reported **BLOCKED** with the exact missing credential—no implied success.

**CI**

- `.github/workflows/ci.yml` on `push` and `pull_request`: Ubuntu, pinned Godot 4.7.2 headless, run domain/integration tests, content validation, generation smoke (reduced 200 planets / 2,000 chunks for CI time), scene validation, art audit; upload reports and contact sheets as artifacts.
- Full-scale generation (≥1,000 planets, ≥10,000 chunks) runs locally and via `workflow_dispatch`; CI parity is documented.
- No Android job initially (templates absent); APK stays a local/CI artifact, never committed.
- CI failures are fixed or reported with logs; a red pipeline is never described as green.

**Evidence**

- `build/reports/overhaul/` holds per-stage reports, screenshots, contact sheets, profiler captures and audio captures.
- Each PR update lists: what passed, what failed, what is blocked, what was not tested.

---

## 13. Stage plan

### Stage 0 — Baseline, plan on disk, MCP, GitHub scaffolding

1. Re-run all four suites cold; boot the real game; capture menu/space/planet shots to `build/reports/overhaul/baseline/`; record runtime errors; compare with historical numbers.
2. Save this plan verbatim to `.opencode/plans/beyond-the-void-overhaul.md`; create `AGENTS.md` (permanent hands-on rules, MCP/ADB commands, evidence paths, screenshot inspection, failure reproduction, PASS/FAIL/BLOCKED/NOT TESTED, determinism and art rules, audio-listening rule, git policy); create `docs/audio_direction.md`.
3. Activate MCP: copy the local addon to `addons/godot_mcp`, enable in `[editor_plugins]`, launch the editor with the project, confirm `godot_project`/`godot_editor_read`, run the game, confirm `godot_input`/`godot_runtime_state`. If disconnected: exact path/port/log blocker, no MCP claims, continue elsewhere, mark MCP-only gates BLOCKED.
4. GitHub: commit baseline on `main`; create `overhaul/procedural-universe`; add `.gitignore` entries, issue/PR templates and `ci.yml`; open issues 0–9 and the draft PR; push. If auth is missing, record the blocker and keep the local branch ready.

**Gate:** fresh baseline evidence; plan + `AGENTS.md` + audio guide present; MCP proven or precisely blocked; branch and CI present; push outcome stated honestly.

### Stage 1 — Movement, controls, camera foundation, combat

- `CharacterBody2D` acceleration/friction, 8-direction animation, chunk collision, cylindrical wrap.
- `CameraDirector` with ON_FOOT, SPRINT, AIM, JETPACK, CINEMATIC; close bounded framing; critically damped follow; aim look-ahead; shake framework.
- Controls: left stick move; right stick aim only (never auto-fires); separate **USE**, **INTERACT**, **SPRINT**, **JETPACK**, **TOOL**, **MENU**; sprint/jetpack each Hold/Toggle and persisted; two/three-finger simultaneous input with independent touch indices; left-handed mirroring; ≥48 dp targets; stamina/energy bars and exhausted/empty feedback. PC: WASD/mouse, LMB use, Shift sprint, Space jetpack, E interact, Q tool, Tab menu, M map, Esc pause.
- Tools: range + LOS validation, reticle lock, scan/sample/dampen beams with muzzle, material particles, rewards, depletion, invalid/blocked feedback.
- Combat foundation: health/shield, rogue drone + aggressive fauna, projectiles, hit feedback, death/respawn without save loss; SPACE_COMBAT scaffold.
- Audio foundation: buses, settings, footsteps, tool loops, UI and combat cues.

**Control matrix:** move only; aim only (no fire); move+aim; use while moving; sprint hold/toggle; exhaustion/recovery; jetpack hold/toggle; empty/cooldown/landing; collision; in/out-of-range and blocked interaction; left-handed; 360 px targets; per-bus mute/restore. MCP primary; `tests/playtest.gd` supplemental.

**Gate:** MCP-driven control/camera/audio-foundation matrix passes with screenshots, runtime state and audio evidence. Commit and push.

### Stage 2 — Crash prologue and progression

- `new_game()` starts on Vela at the crash site, `mode=planet`, ship wrecked, prologue active, no market/flight, limited recipes.
- Crash sequence with CINEMATIC camera, impact shake, dust and audio (music/ambience ducking, emergency systems), skippable.
- Tutorial tied to real actions: move → sprint → jetpack → scan 2 species → gather 2 fiber → craft signal lens → talk to Kasa → repair relay. Objective chip, guidance, journal, dismissible help that never blocks.
- Unlocks: basics at start; lens recipe via tutorial; market after relay repair; ship after repair; advanced recipes by flags. Every locked action names its prerequisite. No duplicate rewards, no soft-lock, failed crafts roll back.

**Gate:** fresh save played by MCP input from crash to relay repair; camera/audio states verified; screenshots each step; mid-prologue save/restore. Commit and push.

### Stage 3 — Procedural universe, ecology, structures

**3A — Determinism and universe engine.** `UniverseGen`, `PlanetProfile`, `NameGen`, sector grid, curated pinning, scan tiers, summaries cache, stable IDs, golden fixtures.

**3B — Planet surfaces and Vela.** `world_gen.gd` v2 with continuous biome noise, landmark clearings, route paths, species affinity, clustered props, blockers, objectives. Vela route: crash → market cove → Kasa → relay ridge → crystal basin → tide shelf → landing region. Streaming 3×3 resident, deterministic chunks, LRU, seamless wrap. Sprite world with tiled ground, decals, props, animated flora/fauna, wreck, structures, shadows, mist, foam. Persistence of depletion/regrowth/discoveries/landmarks.

**3C — Ecology and structures.** Flora/fauna genomes, part-library composition, food webs, behavior templates, generated structures with navigation validation, ship/equipment/material generation, discovery codex.

**3D — Curated planets (Milestone 2).** Brine (ocean platforms/tides/storm), Cinder (ash canyons/vents/dry lightning), Tallow (glacier/ice fog/crystal fields), Threshold Anchor (station decks/artificial light/traffic): profiles, palettes, props, hazards, species, resources, routes, objectives, music/ambience, quests.

**Gate 3A/3B:** ≥3 chunk boundaries and a full longitude circuit back to start by input; no seam/void; depletion/regrowth/save. **Gate 3C:** generation scale suites pass; structures reachable. **Gate 3D:** all five curated planets landed on, explored, saved, with distinct content and audio. Commit and push per sub-stage.

### Stage 4 — Spacecraft, space, entry, landing, black hole

- `SpaceWorld`: inertia, thrust, rotate, brake, camera lead, speed/fuel/energy HUD, targeting, real distances; no stranded state (energy recharge + distress recall).
- Approach: cruise → proximity → orbital scan → entry gate (scanned, aligned, speed) → entry sequence → surface flight at altitude → descent → touchdown. Distant planet taps only select.
- Surface flight: board, takeoff, altitude, horizontal flight, dust/exhaust, landing on flat ground/pad, exit; LOW/HIGH camera; engine audio layered by thrust/velocity/altitude.
- Black hole showcase: Threshold Anomaly with core, accretion disk, lensing, particles, gravitational audio; EVENT_SCALE framing; hands-on tested. Narrative encounter in Milestone 2.
- Coherent transitions across walking/flight/space/entry/surface; no stale music or loops.

**Gate:** MCP route surface → takeoff → space → scan → entry → descent → touchdown → walk, with screenshots and measured fuel/altitude/velocity; black-hole framing; one curated non-Vela planet. Commit and push.

### Stage 5 — UI, pixel pipeline, quality, audio settings

- New theme, title, HUD, menu deck, restyled sheets, map fog/landmarks/player, item icons, settings with volume/shake/reduced-motion, gated market presentation.
- World `SubViewport` pipeline with density, nearest scaling, native UI, snapping; camera/aim invariants verified.
- Quality presets with real differences, matched screenshots and profiler timings; adaptive resolution with hysteresis and forced-pressure test.
- Visuals: ambient modulation, halos/real glow, lights, particles, 3 parallax layers, haze, weather; the full configurable VFX stack above (bloom, light shafts, reflections, glass, water, optional motion blur) with quality-scaled defaults; no muddy filter stack.
- VFX settings panel: per-effect controls, live preview, reset, persistence; verified on every preset and at both target resolutions.

**Gate:** all required screens captured and individually inspected at four sizes; matched quality views with VFX on/off and at every preset; adaptive behavior proven; audio and VFX settings persist; the visual QA artist has reviewed the captures and named defects are fixed and re-captured. Commit and push.

### Stage 6 — Progression and content integration

**6A — Systems.** Wire observations, scanning, gathering, inventory/crafting, dialogue/quests, loadout, finite market, building/production, discoveries, combat risk, save migration into the journey when each becomes relevant. Validate prerequisites/rewards; no early locked content; no duplicate rewards; failed crafts roll back; market requires relay repair and is explained before unlock; recipe discovery, ship-repair requirements, base tutorial and danger zones without placeholder buttons.

**6B — Full-game content.** Quest chain across the curated five, their discoveries, resources, ship upgrades, black-hole finale; procedural planets support exploration objectives, rare resources and endgame discoveries.

**Gate 6A:** one save proves each system reachable/persisting in order. **Gate 6B:** five curated planets completed and saved, plus ≥12 procedural planets visited with objectives. Commit and push.

### Stage 7 — Mandatory hands-on QA

1. **MCP on the running game:** `godot_editor_edit run`, `godot_game_time` freeze/step, `godot_input` real actions/keys/touch, `godot_runtime_state` for state/camera/audio IDs, `godot_editor_read` screenshots/logs, `godot_profiler` frame data. Reproduce → fix → restart → retest the failure and related flows.
2. **Complete fresh-save route:** new game → crash/tutorial → movement → scan → mining → gathering → crafting/repair → ship recovery → takeoff → space → orbital scan → entry → landing → exploration → save → force stop → relaunch → Continue.
3. **Mistakes:** sprint exhaustion, failed craft rollback, hard landing, out-of-range/blocked interaction, market before unlock, combat death/respawn, corrupt-save fallback. Save must never break.
4. **Circuit:** full longitude circuit across streaming boundaries and back by input; jetpack and persistence verified.
5. **Controls:** full Stage 1 matrix via MCP including concurrent move+aim; ADB true multi-touch is BLOCKED if unsupported, never implied resolved.
6. **Camera matrix:** all required captures, measured mode/zoom/shake, framing defects fixed and re-captured.
7. **Rendering matrix:** density settings, sharpness, UI scaling, jitter, adaptive pressure/recovery, logic/input invariance; VFX on/off and every preset; motion blur and reduced motion; settings persistence after restart; matched screenshots + frame times.
8. **Audio matrix:** every listed scenario with capture harness and active-event inspection; fix leaks/overlaps/missing sounds/transitions; listening quality reported separately and BLOCKED if unheard.
9. **Procedural visual audit:** ≥30 regions across Vela, the curated planets and generated planets; species, structure, ship, planet and UI lineups; contact sheets reviewed at gameplay scale with written defects and fixes.
10. **Android (ADB):** install, launch, navigate with taps/swipes/Back/Home, land, save/Continue, force-stop, relaunch; screenshots and logcat; crashes, script errors, force quits, performance.
11. **UI QA:** menu, tutorial, surface, space, landing, mining, combat, inventory, crafting, settings, pause, map, market at four sizes; fix and re-capture.

**Gate:** MCP evidence for every claimed mechanic; camera/rendering/audio matrices; real Android evidence; anything not exercised is NOT TESTED/BLOCKED. Commit and push.

### Stage 8 — Regression, generation scale, Android

- Run domain/integration, UI smoke/playtest, content validation, generation scale (≥1,000 planets, ≥10,000 chunks, ≥2,000 flora/fauna, ≥1,000 structures, ≥500 ships/equipment), scene/load validation, control/gameplay integration, save/load/migration, art audit, audio-state tests, Android export + emulator smoke. Explain added/replaced tests; never inflate counts.
- Export debug APK to `build/android/BeyondTheVoid-debug.apk`; install on API 37 emulator; launch; navigate/play; check logcat; capture evidence.
- Every check labelled PASS/FAIL/BLOCKED/NOT TESTED. No physical-device or production claims. Commit and push.

### Stage 9 — Final gates and delivery

- Re-verify every claimed feature against fresh evidence; list failures, blocked validation and quality limits per planet/system, including camera, rendering, audio listening, generation scale and Android.
- Update `README.md`, `AGENTS.md`, `docs/audio_direction.md`, `build/reports/overhaul/verification.md`, `visual_review.md`, `audio_review.md`, `known_issues.md`, environment/performance reports; mark Milestone 1 vs Milestone 2.
- Finalize the draft PR (or report the exact GitHub blocker), keep the approved plan in `.opencode/plans/`, and preserve `docs/beyond_the_void_spec/` plus pre-existing user changes.

---

## 14. Verification commands (fresh at every gate)

```powershell
$G='C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe'
& $G --headless --path D:\beyond-the-void --script res://tests/run_tests.gd
& $G --path D:\beyond-the-void --script res://tests/playtest.gd
& $G --headless --path D:\beyond-the-void --script res://tools/validate_content.gd
& $G --headless --path D:\beyond-the-void --script res://tools/generation_stress.gd
& $G --headless --path D:\beyond-the-void --script res://tools/ecology_stress.gd
& $G --headless --path D:\beyond-the-void --script res://tools/structure_stress.gd
& $G --headless --path D:\beyond-the-void --script res://tools/validate_scenes.gd
& $G --headless --path D:\beyond-the-void --script res://tools/art_audit.gd
& $G --headless --path D:\beyond-the-void --script res://tools/audio_audit.gd
& $G --headless --path D:\beyond-the-void --script res://tools/visual_audit.gd
```

MCP checks run through `godot_*` tools. Every gate also requires re-import, zero parse errors, viewed screenshots and scanned logs.

---

## 15. Traceability matrix

| Requirement | Primary evidence | Supplemental |
|---|---|---|
| Movement, sprint, jetpack, stamina/energy | MCP input + runtime state + screenshots | playtest asserts |
| Concurrent move+aim, use separate from aim | MCP two-touch input + reticle/fire state | dual-touch injection |
| Camera modes, black hole, shake | MCP camera state + captures | director math tests |
| Pixel pipeline, density, adaptive | MCP screenshots + profiler + scale logs | scene tests |
| Quality presets | matched screenshots + frame times | profiler |
| Audio events, adaptive music, cleanup | event/music state + capture RMS | audio audit |
| Procedural universe | 1,000-seed hashes + visited planets + saves | distribution tests |
| Procedural ecology | 2,000 genomes + visual lineups + codex saves | uniqueness metrics |
| Structures/ships/equipment | 1,000/500 samples + reachability asserts + lineups | stress suites |
| Generated art quality | contact sheets + in-game captures + art audit | pixel-metric checks |
| Five curated planets, routes, objectives | MCP routes + saves + screenshots | stress/save tests |
| Android install/play | ADB screenshots/logcat | APK inspection |
| GitHub workflow | branch, commits, issues, draft PR, CI runs | local reports |

A feature is complete only when it demonstrably changes the running game; parameters, enums or shader files alone are not evidence.

---

## 16. Limits and non-goals

- English only; no release signing or store packaging; no physical-device claim.
- Fauna get authored animation and simple roaming/reaction AI, not full ethology.
- No external audio middleware; Godot native buses/nodes.
- The agent cannot hear rendered audio; technical checks are performed, listening is BLOCKED until a human reviews.
- Generated art may not match hand-pixelled studio quality; every asset is reviewed at gameplay scale and labelled prototype or final, with a defined artist-production pass for gaps.
- Black-hole narrative encounter, five-planet content chain and full rosters are Milestone 2; the engine, showcase and Vela are Milestone 1.
- MCP/ADB limits are BLOCKED with exact prerequisites; never downgraded into implied success.
- A red CI run, failed push or missing credential is reported as such.

## 17. Main risks

- Glow/HDR and SubViewport scaling under Mobile renderer/SwiftShader: verify tier by tier with fallbacks.
- Camera smoothing vs pixel snapping: snapped render position, unsnapped aim, visual tests.
- Generated-art quality: authored part library plus strict composition and silhouette gates; reject and regenerate rather than ship weak output.
- Generation cost at scale: cached biome tiles, summary LRU, chunk time budget, profiler evidence.
- Audio quality: classified drafts and a human listening gate.
- Long input-driven routes: only non-interactive travel may be fast-forwarded, never a mechanic being claimed.
- GitHub automation without `gh`: web/API fallback, otherwise precise blocker.

## 18. Definition of done

**Milestone 1:** a fresh save is playable by real MCP input from crash to relay repair, takeoff, space flight, orbital scan, atmospheric entry, landing, exploration, save/quit/Continue; Vela streams seamlessly around its circumference and back; the camera director handles every on-foot, flight, space, entry, combat and black-hole-showcase mode without losing the player; the pixel pipeline renders sharp nearest-neighbor worlds with native UI and working adaptive resolution; the configurable VFX stack (bloom, light shafts, reflections, glass, water, optional motion blur) visibly changes with each setting and preset; Low/Medium/High/Ultra differ measurably; the procedural universe and ecology engines generate deterministically at ≥1,000 planets and ≥10,000 chunks; the full audio architecture runs with technical evidence and honest listening status; all suites/art/audio audits pass; the Android APK installs and plays on the emulator; reports state exactly what is proven and what is not.

**Milestone 2 (full game):** five curated landable planets plus a broad procedural universe with distinct environments, resources, discoveries, structures and exploration objectives, connected by space flight and the black-hole finale; ≥12 procedurally generated planets verified hands-on; the five-planet progression completed and saved; per-planet routes, audio and objectives verified. Only then is the game called content-complete.

---

## 19. Live user feedback (2026-10-28) — binding additions

These are user-visible requirements, not suggestions. They enter the appropriate stage gate; none
may be silently dropped.

1. **Menu has no seed field.** Remove seed entry entirely. A new journey picks and stores a fresh
   world seed itself; the player is never asked to type one.
2. **Menu UI is too small.** Raise menu typography, control heights, spacing and default window
   size so the title screen reads comfortably on a phone and on desktop.
3. **Menu music is not accepted.** Rework the TITLE state (deeper, slower, less busy/looping
   arpeggio); listening approval remains human-gated. Record the change and keep it distinct from
   explore and combat music.
4. **HUD buttons look random and fail a cockpit layout.** Replace ad-hoc placement with an
   ergonomic thumb-zone grid: primary actions under the right thumb, movement under the left,
   consistent sizes/radii/icon language, safe-area and notch padding, no overlapping bars or
   sticks, verified at 720x1280, 1080x2400 and 360x640.
5. **Controls must not be a cockpit.** Consolidate: one context button performs several actions;
   fewer buttons, each with a clear primary meaning and a secondary long-press/context action.
   Preserve separate MOVE and AIM (concurrent) and a dedicated FIRE path.
6. **Camera is still too close.** Increase base on-foot framing further (beyond the earlier 20%),
   keep the player readable but not speck-sized, keep aim world-space and pixel snapping intact,
   and re-check all camera modes and biome scales.
