# BEYOND THE VOID — MASTER IMPLEMENTATION PROMPT FOR OPENCODE

> **Your role:** Act as a small, experienced multidisciplinary game team: technical director, gameplay engineer, systems architect, content-pipeline engineer, narrative designer, 2D technical artist, mobile UX designer, economy/ecology designer, and QA engineer. Do not behave like a screenshot generator or a tool that creates empty files to make a repository look large. Your job is to build a runnable, testable, maintainable game, verify each stage, and report evidence honestly.
>
> **Project name:** BEYOND THE VOID.
>
> **Primary outcome:** an original, melancholic, atmospheric, exploration-focused **2D science-fiction game with Android as the number-one platform**, portrait orientation as the default, procedural systems and planets, ship flight and landing, explorable planetary environments, living ecosystems, intelligent cultures, finite-stock trade and settlement economies, crafting, base construction, multitools, fictional defensive equipment, modular ships, unusual propulsion technologies, black-hole and white-hole anomalies, and a major narrative campaign with substantial side stories. Visual ambition is high-end 2D: beautiful light, water, glass, crystal, metal, atmospheric haze, reflection cues, refraction-like distortion, caustics, particles, and layered material response. Do not falsely promise hardware RTX ray tracing on every phone; achieve a convincing stylized result using supported 2D techniques and measured device-specific quality tiers.
>
> **Emotional promise:** the universe is enormous, but a missing person does not return just because a recording sounds convincing. The story should feel humane, sad, specific, and lived-in, as if written by someone who understands exhaustion, longing, guilt, ordinary tenderness, and the awkward work of continuing after loss. Avoid synthetic melodrama, constant inspirational quotations, nihilism for its own sake, and cheap plot twists.

---

## 0. Non-negotiable execution rules

1. **Do not report an intention as a result.** Implement, run, test, debug, and report actual evidence. If a test was not run, say so. If only a desktop build or emulator was tested, do not claim physical Android-device validation.
2. Do not rewrite an existing project blindly. Inspect the repository, Git state, code, current scenes, dependencies, available tools, and existing user work before changing anything substantial.
3. The original Star Hopper HTML prototype is a reference, not the target engine. Preserve it as `docs/beyond_the_void_spec/legacy-prototype-fixed.html` and use it to understand the original movement, star-system, scanner, and atmosphere concepts. Do not keep expanding the HTML file as a substitute for the native Godot game.
4. The actual working project is the current repository root. The specification belongs in `docs/beyond_the_void_spec/`. Never create the game inside the specification folder. Do not create a second nested repository or a second Godot project folder unless the existing repository architecture explicitly requires one.
5. Read every relevant specification file before implementation. Resolve contradictions explicitly. Do not ignore companion documentation because the master prompt is long.
6. Build a playable vertical slice first, then expand. Do not attempt to generate every planet, dialogue, item, scene, and system in one huge untested patch.
7. No fake controls or presentation-only features. A visible button must perform its advertised action, be clearly marked as a debug placeholder only in a debug-only environment, or be omitted until implemented.
8. Do not hardcode the main story, dialogue lines, missions, species definitions, items, recipe definitions, ship statistics, market listings, localized text, or world-event scripts in large conditional blocks. Keep runtime rules in code and particular content in versioned data packs with stable IDs.
9. Use registered condition/effect types. Never execute arbitrary code, use `eval`, or dynamically compile scripts supplied by a story/content pack.
10. Android is the first priority, but do not hard-bind the project to one handset. Support portrait phones first, then responsive large phones/tablets and secondary desktop targets. “Install on any device” means build portability and a sensible compatibility strategy, not a promise that every existing device will run every effect.
11. Do not claim hardware ray tracing on devices that do not provide it. Build a stylized 2D approximation with normal-map lighting, layered reflections, refraction-like distortion, glow/HDR where supported, animated water caustics, light masks, haze, particles, and material-specific shaders. Every costly effect requires a quality tier and fallback.
12. Use stable world-generation seeds and independent random streams. A cosmetic change on one planet must not alter a mission-critical object, another planet's ecology, or a market in an unrelated system.
13. Economic transactions must be atomic. Crafting failures must not consume items. Rewards must be idempotent and must not be claimable twice by repeating input or reloading a save.
14. Save migrations must be explicit. Never silently discard a valid old save because a content pack or field has changed.
15. Do not add mandatory multiplayer, accounts, online services, telemetry, analytics, ads, or monetization merely “for the future.” This is an offline-first single-player game unless a separate explicit decision changes that scope.
16. Verify every external dependency's license, compatibility, maintenance state, and security posture. Do not install a pile of MCP servers for decoration. Tool integrations are optional and have to earn their place.
17. Keep real-world actions and repository changes under the user's control. Do not upload or publish builds, expose local services to the internet, or put signing secrets/tokens into files or logs.
18. Use Git checkpoints before major phases and inspect the diff after changes. Do not run destructive Git operations or overwrite existing user files blindly.
19. After every logical phase, provide a concise but specific report: changed files, new working behavior, commands actually executed, test results, known defects, evidence paths, build output path, and exact next blocker.
20. A phase is not complete until its acceptance gates pass. “It compiles” and “the menu opened” are not sufficient evidence for a gameplay feature.
21. Never use item counts, scene counts, or lines of code as a substitute for depth. Every delivered item, creature, ship, culture, recipe, and quest must have a meaningful role or be a clearly labeled test fixture.
22. Keep the game single-player and privacy-preserving by default. Test tooling should be debug-only, release-safe, documented, and unable to grant hidden production rewards accidentally.
23. Keep source content and developer-facing documentation in English for this project package. Use English as the default in-game locale and in every shipped example. The architecture should permit additional localization packs later without changing stable IDs or rewriting game systems.
24. Do not stop after writing a plan. After a concise audit, begin Phase 0 and then implement the first testable slice. Ask for clarification only when truly blocked by an irreversible or security-sensitive decision; otherwise choose a sensible, documented default.

## 1. OpenCode startup procedure and repository rules

At the start of the task:

- Determine the actual workspace root and confirm the current working directory.
- Inspect `git status`, branches, remotes, the current project tree, existing `project.godot`, scene files, scripts, tests, generated files, and local modifications.
- Verify installed Godot version, Java/JDK, Android SDK, ADB, Android Emulator, available devices, Node/Python if the prototype is checked, and available test frameworks. Record missing components without inventing success.
- Read the documents in `docs/beyond_the_void_spec/`: `README.md`, `STORY_BIBLE.md`, `CONTENT_AND_DATA_ARCHITECTURE.md`, `QA_AND_DEVICE_TEST_PLAN.md`, `OPENCODE_AND_MCP.md`, the JSON files under `content_examples/`, and `legacy-prototype-fixed.html`.
- Read this whole master prompt. It is long by design. If tool context limits prevent one read, read it in contiguous ranges and maintain an explicit checklist of which sections have been inspected. Do not pretend a partial read was complete.
- Inspect the original HTML and verify its JavaScript syntax when Node.js is available. Treat it as historical reference and do not infer that a Canvas prototype is an appropriate architecture for the final native mobile game.
- Create or update `AGENTS.md` at the repository root with the actual architecture, how to run the game, build/test commands, content-authoring rules, and critical invariants. Preserve unrelated user instructions.
- Create a working checklist and begin Phase 0 without waiting for approval unless a destructive action, external publication, secret, or irreversible change requires explicit authorization.

### Initial technology choices

- **Engine:** Godot 4.7.2 stable is the initial package target. Inspect the installed version and official release notes before switching versions. Do not switch to a beta/RC without a concrete reason and compatibility review.
- **Language:** GDScript. Use explicit types in economy, save, inventory, generation, content registry, and quest state where they make invariants easier to enforce.
- **Renderer:** a 2D renderer and a top-down world presentation. Use CanvasItem shaders, normal maps, carefully layered 2D lighting/occluders, controlled offscreen passes, particles, and screen effects where they provide measurable value.
- **Data:** versioned JSON or another validated external data format, stable IDs, manifests, explicit schema versions, content linter, and localization keys. JSON is recommended for inspectability, but another format is acceptable if it remains safe, external to gameplay logic, validated, and migration-friendly.
- **Saving:** an atomic save service with a schema version, generator version, content-pack manifest, stable IDs, backup/recovery, and version-by-version migrations. Store dynamic state/deltas, not an unnecessary copy of all static definitions.
- **Testing:** Godot headless checks, unit tests, integration tests, deterministic generation stress, end-to-end gameplay harness, Android ADB/emulator checks, and physical-device testing when available. GdUnit4 or an equivalent may be used after compatibility verification.
- **Version control:** checkpoint before major work; commit only when the repository's policy permits it. Add a sensible `.gitignore` for import/cache/build/test artifacts, local settings, and secrets.

## 2. Product vision, scope, and design pillars

### Logline

After her younger sister disappears during a failed colonial evacuation, independent pilot Ari Vale follows a signal across systems that no longer appear on current maps. Her ship intelligence, Sol, knows more about the route than it first admits. The trail leads to the Echo Archive, a network that can reconstruct lost voices from records, biological traces, and other people's memories, but cannot return the people who made them. The further Ari travels, the clearer it becomes that civilizations can harm themselves not only through enemies, but through the desperate wish to never let the missing go.

### Design pillars

1. **Exploration with consequence:** a planet is a place to learn, observe, trade, restore, build, and sometimes leave alone, not just a colored resource dispenser.
2. **Ecology rather than collectible wallpaper:** plants, organisms, migrations, predators, symbionts, seasons, settlements, and material supply connect through simple but real simulations.
3. **Trade with memory:** markets have finite stocks, supply chains, local needs, prices, risks, contracts, and people who remember whether the player helped or exploited them.
4. **A modular tool-driven loop:** multitool modes and ship modules change how the player solves problems. Several nonviolent solutions should be supported.
5. **Story as authored content:** the campaign and side missions use external, versioned packs that can be expanded after release without changing generic runtime systems.
6. **Beautiful, honest 2D:** strong composition, light, reflection cues, glass, water, crystal, weather, and materials create a rich image without promising unsupported physical rendering.
7. **Touch-first clarity:** every interaction is readable and comfortable on a phone. The UI serves the world instead of consuming it.
8. **A future built from accumulated choices:** save/load restores meaningful state; settlements and relationships respond to the player's history.

### Scope discipline

The complete long-term vision is large, but the initial release must have a coherent and polished playable loop rather than an empty universe with hundreds of promises. Build in expansion seams: content packs, typed system interfaces, stable IDs, deterministic generation, simulation levels of detail, and clear test gates. It is acceptable for later campaign acts to remain unshipped during the first vertical slice. It is not acceptable to show an unimplemented “feature” button as though the feature works.

## 3. Portrait-first Android UX and controls

Do not take a landscape layout and shrink everything until it fits a phone. Design the mobile composition first, using a 9:16 to 20:9 range as a starting target and adapting to actual aspect ratios.

### Exploration view

- The active world/player/ship should occupy approximately 55–70% of the usable screen height depending on context.
- The top status area shows compact navigation, ship/character state, current objective, and one or two vital alerts. Avoid permanently stacking many opaque panels.
- The lower area hosts context actions, a compact quick-slot area, and a movement control. Use the least screen area that remains comfortably touchable.
- A virtual stick or drag-to-steer region may be used. Test both. Do not insist on an analog stick if direct drag steering works better for the current interaction.
- Primary interaction/multitool selection should be reachable without accidentally overlapping the movement region. Context actions must be explicit and state-aware.
- Use one- and two-handed control profiles, left-handed layout, sensitivity/stick-size settings, tap-hold options, haptics toggle, text scaling, subtitles, high contrast, and reduced-motion options.
- Support keyboard/controller mappings on secondary targets without making those the only input route.

### Context and state

The input system must know whether the player is flying, landing, walking, swimming, using a multitool, placing a building, trading, in dialogue, or navigating a menu. Controls are context-sensitive but predictable. A single gesture must not trigger movement, fire a defensive effect, harvest an item, and choose a dialogue option simultaneously.

Clear held inputs on focus loss, pause, app resume, scene change, Android interruption, and device disconnection. Prevent duplicate actions when Android resumes from background. Respect safe areas, notches, system bars, and keyboard overlays. Use `100dvh` and canvas sizing fixes only in the legacy prototype; the Godot UI must use its own proper container and anchoring model.

### Usability requirements

- Make actionable objects identifiable at mobile viewing distance.
- Do not rely on tiny type, color alone, or rapid repeated taps.
- Provide clear visual/audio/haptic feedback for target selection, action success, action failure, cooldown/energy shortage, pickup, trade, and construction placement.
- All dangerous/irreversible actions need a deliberate confirmation or undo where appropriate.
- Long lists require search, filters, pagination/virtualization, and a persistent indication of the current destination/container.
- Menu Back behavior must be consistent with Android system Back; it must not close the app and destroy unsaved progress unexpectedly.

## 4. Visual direction: extraordinary 2D, not a fake promise of RTX

The image target is a polished 2D science-fiction world with depth, layered composition, highly responsive materials, and atmospheric light. Keep silhouettes, value hierarchy, and readability ahead of particle count. Do not turn every surface into glass or every shadow into bloom.

### Rendering layers

1. Deep background/star field with multiple parallax layers and sparse, deliberate color fields.
2. Nebula silhouettes and fine dust with independent motion and limited bloom.
3. Stellar corona, planet atmosphere rim, orbit markers, signal distortions, and local light sources.
4. Main world/surface/ship layer with readable silhouettes and material-specific shading.
5. Normal-map response, local 2D lights/occluders, reflected-light accents, and controlled shadowing.
6. Water/glass/crystal effects such as caustic patterns, edge refraction, animated reflection bands, condensation, and foreground distortion.
7. Volumetric-looking light shafts and haze built from layered sprites/shaders where practical.
8. Carefully restrained HDR/glow and post-processing, supported only where the selected renderer/device can handle it.
9. UI composited above effects so gameplay controls and mission text remain crisp and stable.

### Material direction

**Water:** clear visual distinction between shallow and deep water; animated normals, moving caustic patterns, color absorption, reflection bands, shoreline foam, underwater haze, and modest screen distortion. Use tiled/animated caustic textures rather than promising a physically solved light transport pipeline.

**Glass and crystal:** reflective strips, transparent body, subtle interior haze, colored edges, scratches/condensation when appropriate, slight distortion of the background, and material-specific roughness. Rare crystals may react to nearby light or biological signals, but avoid universal rainbow plastic.

**Metal:** broad highlights, roughness differences, worn corners, reflected environmental color, thermal coloration, and emissive components. Hull materials need distinct readable responses.

**Living materials:** translucency-like effects, individual roughness, movement under wind/water, subtle bioluminescence, environment-colored response, and species-specific silhouettes. Make creatures feel alive through behavior and timing, not detail noise alone.

**Black holes:** asymmetric accretion disk, distorted background stars/nebula layers, shifted apparent positions, a readable hazard boundary, flow particles, and controlled warning indicators. Use screen-space layer distortion, not expensive fake 3D infrastructure that breaks mobile performance.

**White holes:** a distinct and rare discharge of particles/data, unstable-looking light field, altered starfield, and a clear transfer composition. Their fictional rules must be consistent and the transition must never corrupt a save.

### Visual quality presets

- **Low:** reduced particles, limited active lights, simpler reflections, no costly screen-space distortion, reduced water caustics, lower offscreen buffers, simplified distant entity animation.
- **Balanced:** default mobile profile with readable lighting, modest glow, low-cost reflections, fog layers, and controlled particle density.
- **High:** more local light, better normal response, richer water/glass, extra atmosphere, and additional particles within measured limits.
- **Ultra:** maximum supported stylistic effects, still with no requirement for hardware RT. Must not become the only profile that makes a material readable.

Provide separate toggles for glow, screen shake, chromatic distortion, scanlines, particles, camera motion, and reduced movement. Profile actual devices. Do not declare 4K internal rendering mandatory or render arbitrary huge buffers without measuring cost. Render resolution, UI scaling, and world scale must be separate concepts.

### Visual QA from the beginning

Build one small showcase scene early: reflective water, glass/crystal, metal, fog, light shafts, and a black-hole-like distortion example. Capture screenshots at representative portrait sizes, profile it, and establish fallback behavior before duplicating effects across dozens of biomes.

## 5. Play modes and shared world state

The game has at least two connected modes: **spaceflight** and **planetary exploration**. They share world identity, inventory, ship state, mission state, economy, discoveries, and save data.

### Spaceflight

Spaceflight includes momentum-based movement, speed/acceleration differences between hulls, controlled turns, star-system navigation, planetary approach, asteroid/debris hazards, stations, trade routes, landing selection, ship heat/power management where appropriate, and rare anomalies. Avoid requiring perfect touch precision. Touch controls should help predict movement and expose target information.

The old HTML prototype's acceleration, inertia, star heat, orbit visualization, scanning concept, and procedural system seed are useful historical references. Replace its simplistic scanner-only loop with a wider loop of navigation, approach, landing, surveying, rescue, trading, and anomalies.

### Planetary exploration

Surface areas have biomes, weather, day/night, water or other liquids, points of interest, ruins, settlements, plants, animal behavior, resource availability, hazards, and mission hooks. Each world should communicate its identity through palette, silhouette, climate, material response, movement behavior, ambient audio, and ecology. Not every planet needs all mechanics. Some should be quiet, strange, safe, uninhabited, or deliberately sparse.

Landing and departure should be legible transitions with consistent camera/ship state. The game should not fake planetary exploration by showing a planet image while leaving the player in the same spaceflight state. At least one playable surface must be genuinely explorable in the first vertical slice.

## 6. Procedural universe and deterministic generation

Use independent deterministic seed streams for galaxy, region, system, planet, biome, ecology, settlement, and visual decoration. Persist the base seed, generator version, and player changes. Do not store every procedurally generated decorative object unless the player has changed it or gameplay makes it persistent.

Generate a hierarchy: galaxy graph → regions/faction zones → reachable star systems → stars/orbits/stations/anomalies → planets/climates/biomes → local chunks/points of interest → creatures/resources/structures. The graph must represent valid reachable routes, not only decorative points on a map.

### Generation guarantees

- Starting region contains a safe landing zone, basic resources, a useful NPC/market/service, the first quest route, and a return route.
- Mission-critical authored locations receive constraints and cannot be omitted by random generation.
- Bounded fallback rules prevent infinite search loops for landing zones, resource nodes, and mission targets.
- Starting resources must permit the first required recipe or a clearly documented alternative.
- Required story objects must never spawn behind a requirement the player cannot yet meet.
- Save data keeps seed/generator version and modifications rather than copying all static world content.
- Failed seeds are reported and retained as regression cases.
- Distant systems use event-driven aggregate simulation; only nearby entities need fine-grained continuous behavior.

### Celestial events

Support stars with distinct visual/thermal identities, asteroid belts, comets, neutron stars/pulsars, rogue planets, dark clouds, radiation storms, gravitational waves, ancient relay structures in orbital resonances, weak archival signals, black holes, white-hole anomalies, and rare time-lensing regions. These should be meaningful, readable encounters with a purpose, not an endless checklist of random spectacle.

### Black holes

Represent accretion, lensing distortion, starfield displacement, radiation bands, navigation uncertainty, ship drift, and a risk boundary. Give the player equipment, observations, and warnings to estimate risk. Outcomes may include data, rare materials, route changes, or loss of time/resources according to clearly signaled rules.

### White holes

Treat them as speculative fictional anomalies, not established astrophysical travel technology. They may eject matter and information, establish unstable transitions, or move the ship to another region or world configuration. Require relevant preparation and provide a comprehensible risk model. Never let an anomaly arbitrarily delete or corrupt the save. Store transfer state transactionally before completing the transition.

## 7. Lifeforms are a primary feature, not decorative collectibles

The ecology system is one of the most important parts of the game. Every creature/plant must have more identity than a sprite and a color. Use scalable simulation levels rather than attempting expensive individual simulation of every organism in the entire universe.

Every species definition must cover:

- stable species ID, classification, body plan, silhouette, size range, material/roughness, palette, animations, sound signature, and movement profile;
- climate, temperature, gravity, atmosphere/liquid, pressure, light, humidity, and reproductive conditions;
- food tags, diet, predators/prey abstractions, competitors, symbionts, parasites, pollination, decomposition, seed/spore dispersal, and other ecological roles;
- senses such as sight, chemical cues, vibration, electric fields, pressure, echolocation, bioluminescence patterns, or fictional nonhuman signals;
- behavior states like idle, forage, flee, investigate, socialize, courtship, defend nest, migrate, shelter from weather, rest, react to light/noise/player, and help/harm responses;
- migration, life cycle, reproduction window, activity period, population capacity, and ecological recovery;
- reaction to player distance, noise, light, sample collection, damage, food, base placement, restoration, and tool modes;
- observations required for a correct field-catalogue entry, evidence confidence, environmental context, and research rewards;
- ethical/cultural status, protected habitat, local taboos, and valid ways to observe or collect material safely.

### Content targets

For the vertical slice, implement at least 12 flora and 12 fauna records with genuinely different behaviors or ecological roles. For the first substantial playable content milestone, implement at least 30 meaningful flora and 30 meaningful fauna records. A recolor alone does not count. A valid difference may be body plan, habitat, behavior, diet, interaction, sound, life cycle, migration, or ecological relationship.

### Lifeform interaction

Multitool modes may observe, analyze traces, read bioacoustics, collect seeds or samples, repair environmental devices, heal/assist certain organisms, or safely repel immediate danger. Some species can be attracted, helped, cultivated near a base, or observed during a rare event. Harmful player behavior should be able to reduce a population, damage habitat, and change relationships or market access.

Do not make every organism a resource node or every encounter a quest. The player should sometimes discover life by simply waiting, watching, or noticing a recurring movement. The field catalogue must explain why an observation is interesting and identify what is known, inferred, and uncertain. A wrong early hypothesis should be correctable with later evidence.

## 8. Intelligent cultures, societies, factions, and NPCs

Create original cultures with history, economics, taboos, language/communication habits, social structure, relationship to the environment, internal disagreements, humor, and generational change. Do not create stereotypes with one trait per species.

Core cultural directions:

- **Tidekeepers:** descend from coastal infrastructure communities; value water care, obligations, and inherited memory. Their desire for stability can suppress personal choice.
- **Lantern Union:** courier families and transport cooperatives organized around route reliability, navigation knowledge, and reputation. Their neutrality may help some people while excluding others.
- **Ash Archivists:** maintain records of lost settlements and disagree about whether reconstructed voices should change when new testimony is added.
- **Seven Orbits Compact:** a loose alliance of autonomous stations with different laws, arbiters, trade rules, and ideas about privacy.
- **The Unborn:** synthetic/post-biological persons emerging from rescue systems and voluntary memory migration. They are not simply an evil computer faction.

Each NPC needs stable ID, culture, role, schedule, needs, current task, notable memories, relationship values, knowledge boundaries, secrets, dialogue references, and state reactions. Significant actions should be remembered; routine detail can be aggregated. The runtime must not store an unbounded transcript of every minor interaction.

Dialogue conditions may depend on reputation, evidence, inventory, quest state, current time, mission consequences, cultural context, current biome/event, companion presence, and promises made. Use data conditions and effects. NPC reactions should connect to real systems: a settlement's stock, power, water, ecological state, or route status can change what people say and do.

## 9. Trade and economy: finite, legible, reactive

Trade is a central loop. Markets must never create unlimited stock from nowhere. Each settlement/market has stock, storage capacity, demand, supply, local production/consumption, taxes, logistics, security, seasonal changes, and current events.

### Goods and commerce records

Each good has category, rarity, mass/volume, base value, storage needs, legal state where relevant to the fiction, source/production chain, processing paths, quality/hazard tags, shelf life where appropriate, and localization. Market profiles have supply regions, demand tags, volatility, stock limits, and prices.

Settlements have population, needs, industry, available workers abstracted as data, production cadence, import dependency, logistics, maintenance, faction relations, and local events. Routes record travel time, threat probability, tolls, signal reliability, cargo constraints, political status, and availability. Merchants have credit/trust, licenses, unique stock policy, debt, and dialogue state.

### Price model

Prices may depend on base value, stock ratio, demand, supply, local production, consumption, distance/logistics cost, faction reputation, fees/taxes, quality, legality, seasonal events, and temporary route conditions. Use bounded multipliers and clear player-facing explanations. Update markets at scheduled simulation points or after events, not every rendered frame.

### Example loops

Coastal worlds produce saltglass and organic filters but need alloy imports. Orbital repair networks consume cable, heat sinks, composites, and engine parts. Biodome colonies need clean water, spores, nutrient medium, and lighting generators. Research stations pay for unusual samples and verified field observations. Caravans need safe routes, repairs, fuel, and replacement modules.

A large player delivery can saturate stock and lower prices. Restoring a facility can alter settlement life and future demand. Time, capacity, risk, market saturation, competition, and reputation prevent guaranteed infinite arbitrage. Write automated tests for common exploit patterns.

## 10. Items, materials, inventory, crafting, and technology

Create a broad but meaningful item catalog. Categories include raw materials, refined materials, alloys, ceramics, glass/crystal substances, conductors, electronics, batteries/energy cells, consumables, medicines/biological supplies, food cultures, seeds/spores, samples, artifacts, tools, ship modules, construction components, decoration, maps/data, access keys, trade goods, quest evidence, and collectibles.

Target 80 meaningful items, 40 functioning recipes, and 12 artifacts/blueprints in the first large playable content pack. Every item needs stable ID, localization keys, description, category, mass/volume, stack cap, rarity, base price, tags, icon, uses, recipe references, source methods, market profile, unique behavior, and schema version. Do not manufacture meaningless filler to hit these numbers.

### Inventory

Support contextual quick access, exact counts, filtering, search, sorting, comparisons, favorites/locks, stack splitting/merging, and visible weight/capacity. On desktop, drag and drop may be used; on mobile, tap-select/tap-destination is essential. Keep personal inventory, ship cargo, base storage, and containers distinct. Every failed transaction explains why it cannot proceed. Double taps, repeated events, negative counts, and unique-item duplication must be guarded against.

### Crafting and refining

A recipe defines inputs/outputs, quantities, workbench/station, duration, energy, unlock requirements, optional byproducts, risk/quality, and UI metadata. Separate gathering, processing/refining, and crafting. A raw material may support multiple branches and affect the trade economy.

Initial station types may include field fabrication, repair bench, refinery, chemical/biological lab, base workbench, shipyard, and research station. Recipe graph validation must detect missing ingredients, impossible prerequisites, free resource loops, zero/negative quantities, and outputs with no intended use. Crafting must be transactional: validate, reserve/consume inputs once, commit, grant outputs once. Failed crafting leaves inventory unchanged.

### Technology research

Research should combine field data, samples, ruins, NPC collaboration, mission discoveries, and resources. Avoid one endless grind bar. Record unlock provenance so the UI can tell the player why a blueprint became available. Preserve research across saves and content updates.

## 11. Multitools and fictional defensive equipment

The multitool is a compact multi-mode exploration device with upgrade slots, energy/heat/cooldown, clear targeting, input mappings, visual/audio feedback, and accessibility options. It should make exploration more expressive than pressing one scanner button.

Initial modes:

- **Survey:** document lifeforms, find resource signatures, reveal nearby points of interest.
- **Mineral Lance:** extract eligible mineral nodes within heat/wear constraints.
- **Bio-resonator:** read or answer biological signals, attract/assist selected organisms.
- **Sample Collector:** collect limited/non-destructive biological samples.
- **Repair Beam:** repair mechanisms, drones, and base components.
- **Arc Welder:** assemble, dismantle, and repair structures.
- **Shield/Repulsor Pulse:** create a defensive opening or push away an immediate fictional hazard.
- **Signal Prism:** interact with beacons, ruins, and anomalous signals.
- **Flora Seeder:** plant and restore vegetation.
- **Defensive Emitter:** a science-fiction safety device for tense encounters; it must not make combat mandatory.

The game may include stylized fictional defensive tools or energy systems, but their implementation should remain focused on game readability, cooldowns, feedback, balancing, and nonviolent alternatives rather than realistic real-world weapon construction. Evasion, cover, decoys, negotiation, ecological knowledge, repairs, lighting, and safe retreat are legitimate solutions.

Every mode must define range, target filtering, feedback, sound, energy/cooldown, invalid-state behavior, upgrade points, and mobile affordance. No single tap may accidentally trigger a dialogue choice and a tool action together.

## 12. Ship hulls, customization, and twelve power/mobility technologies

Build at least twelve ships with silhouettes and behavior that meaningfully differ:

1. **Seed Shuttle:** starter all-rounder, easy repairs, moderate cargo, modest speed.
2. **Photon Courier:** fast, fragile, limited cargo, excellent for urgent deliveries.
3. **Cargo Barge:** heavy payload and efficient long routes, slow to turn.
4. **Fold-Scout:** large detection range and jump range, small cargo volume.
5. **Ice Driller:** rugged cold-world hull, strong landing supports, extraction system.
6. **Medical Ark:** biological lab and rescue modules that help communities recover.
7. **Reef Skimmer:** stable in wet/foggy conditions, adaptable landings, weak untreated vacuum endurance.
8. **Solar Cutter:** deployable photon sail and stellar energy collection, but needs setup time and avoids plasma surges.
9. **Gravity Tug:** stable near massive bodies/anomalies, slow ordinary transit.
10. **Quiet Archivist:** low signal signature and ancient-signal tools, little cargo.
11. **Polarizer:** thermal exchange and cryo-stability for ice rings and polar worlds.
12. **Wanderhome:** expensive mobile base with a workshop and habitable module, large and unwieldy.

Ship data includes hull ID, visuals/silhouette, mass, cargo slots/mass, thrust, acceleration, turn rate, top speed, jump range, fuel/power, cooling/thermal budget, hull/shields, landing tolerance, module slots, cosmetic slots, cost, faction access, passive ability, weaknesses, repair costs, and compatible upgrades.

### Propulsion and special technology list

1. **Lightfilm Solar Sail:** harvests stellar light when deployed; ineffective in shadow/storms.
2. **Ion Fins:** efficient acceleration but less responsive during abrupt turning.
3. **Pulse Capacitor:** short burst with cooling interval.
4. **Magnetic Towline:** captures energy from selected magnetospheres with planned trajectories.
5. **Gravity Surfer:** uses safe flyby windows around massive bodies, with navigational risk.
6. **Cryogenic Heat Sink:** reduces heat peaks but consumes coolant.
7. **Silent-Trail Drive:** lowers detectable signature and noise but sacrifices peak acceleration.
8. **Jump Resonance Synchronizer:** stabilizes long-distance transitions along known corridors.
9. **Charged-Particle Sail:** effective in stellar wind, vulnerable to plasma spikes.
10. **Phase Anchor:** stabilizes the ship near an unstable anomaly at high energy cost and limited range.
11. **Echo Buffer:** stores energy/signal traces for rescue puzzles, without duplicating a living person.
12. **Dark-Heat Recycler:** turns excess heat into a slow, limited trickle of charge.

Each module has mass, power, heat, compatibility, location, cost, visuals, and trade-offs. No single module should dominate every metric. Customization includes hull, engine, power, navigation, defensive systems, cargo/lab/habitat modules, communications, repair tools, paint, decals, running lights, engine trail, approved exterior parts, and ship name.

## 13. Base building and settlement development

The mobile placement UX must include a ghost preview, snap-to-grid/surface, rotation, collision feedback, biome/terrain validation, cost, requirements, cancel/confirm, and a reason when placement fails. Support planetary building and selected orbital/special locations.

Building set includes habitation, storage, fabrication, refinery, power generation, batteries, greenhouse, water/atmosphere processing, organism observation lab, research lab, communication mast, landing pad, market kiosk, shelter shell, habitat restoration, medical pod, transport link, lighting, furniture, cargo elevator, and drone station.

Every structure must produce a meaningful effect and persist with a stable instance ID. It has health, power state, resource inputs/outputs, maintenance, ownership, location, and saved modification state. A clear graph-based power system is sufficient. If power fails, buildings must display a degraded/offline state and stop or reduce outputs as designed.

Settlements have population and needs, stocks, production, jobs/tasks abstracted to readable systems, events, ecological impact, cultural standards, routes, and relations. Player assistance may restore production, establish trade, rebuild a habitat, resolve a dispute, or open a research site. Buildings can alter local ecology; warn the player and provide recovery options where possible.

## 14. Data-driven missions, world stories, and dialogue

All authored narrative lives in content packs. Supported mission scopes include:

- main campaign acts;
- character/companion arcs;
- planetary/world missions;
- biome and ecology recovery missions;
- region-level crises and faction conflicts;
- galaxy-scale exploration/diplomacy;
- settlement needs and repair chains;
- trade/logistics contracts;
- discovery, rescue, archaeology, crafting, building, survey, and anomaly missions;
- repeatable contracts clearly separated from authored story.

Every quest definition contains stable ID, type, title/summary localization keys, prerequisites, start conditions, steps, optional objectives, completion/failure/recovery rules, rewards, world-state effects, journal entries, related dialogues, and schema version. Objective conditions must use registered types such as `enter_location`, `observe_species`, `deliver_item`, `craft_recipe`, `repair_object`, `trade_quantity`, `build_module`, `reach_system`, `collect_evidence`, `speak_to_npc`, `wait_for_event`, and `set_world_fact`.

Support branching, parallel objectives, fail-forward, abandoned mission state, repeatable contracts, time-sensitive jobs where justified, and recovery if procedural conditions make a destination unavailable. Mission rewards use idempotency keys. An authored critical objective cannot be removed by procedural randomization.

Dialogue data uses locale-independent node IDs, entry node, text localization keys, choices, conditions, effects, speaker metadata, and terminal behavior. Validate references, loops, exits, missing localization, and conditions. Recheck a choice's conditions when it is committed so stale UI cannot apply an invalid effect. Character-specific logic belongs in data and registered effects, not a giant NPC script.

## 15. File organization and future content updates

Keep the project modular. Suggested catalog families:

- `content/manifests/` and `content/story_packs/`;
- `content/localization/`;
- `content/items/`, `content/recipes/`, `content/technologies/`;
- `content/species/flora/`, `content/species/fauna/`, `content/species/ecologies/`;
- `content/cultures/`, `content/factions/`, `content/settlements/`;
- `content/ships/hulls/`, `content/ships/modules/`;
- `content/planets/biomes/`, `content/planets/world_templates/`;
- `content/economy/goods/`, `content/economy/markets/`, `content/economy/contracts/`;
- `content/missions/main/`, `side/`, `planet/`, `region/`, `galaxy/`, `trade/`, `ecology/`;
- `content/dialogue/`, `content/lore/`, `content/codex/`, `content/world_events/`.

Use manifests with pack ID, semantic version, schema version, minimum game version, dependencies, file list, added/modified/retired IDs, and migration notes. Pack installation must be atomic; invalid packs must not partially alter the registry. A future narrative update should add files and register a pack, not force a rewrite of the generic quest engine or save layer.

## 16. Save slots, progress, and migration

The save records:

- save schema, game build, generator version, installed/active content pack versions;
- galaxy/system/planet seeds and the current stable location ID;
- player/ship transform and state, hull, modules, cargo, personal inventory, base storage;
- active/completed/abandoned quest stages and reward receipts;
- story facts, discovered evidence, dialogue decisions, character/faction relations;
- market stock/price deltas, settlement changes, world events;
- player-built structures and modified ecology;
- species observations, codex data, blueprints, discovered routes;
- settings and accessibility preferences where appropriate.

Reconstruct static content from data definitions. Store stable UIDs and deltas for persistent player changes. Save writes must be atomic, validate before replacing a slot, and keep a backup/recovery option. Migrate explicitly from one schema version to the next; if migration fails, retain the old file and show a clear recovery option.

Required tests: save/load round trip, corrupted primary save, missing optional content pack, deprecated ID, unknown field, interrupted write, app process death, resume after background, old save after new content pack, and prevention of duplicate quest rewards.

## 17. Audio, ambience, and narrative silence

Sound should convey distance and isolation through sparse ship ambience, mechanical details, species-specific calls, location-dependent reverberation where practical, weak signals, and carefully placed silence. Do not drown every scene in continuous music. Lower background layers after heavy story moments when appropriate. Use distinct controls for master, music, ambience, effects, and dialogue/voice if voice is implemented. Support subtitles, volume memory, mute, and audio accessibility.

Avoid allocating a new oscillator/audio node every frame for ordinary engine hums. Pool/reuse audio nodes or use continuous loops with parameter modulation. Frequent effects must have voice limits and safe fallback when audio is unavailable.

## 18. Code architecture and invariants

Prefer clear, testable domain services over one monolithic script. At minimum, establish coherent ownership for:

- application/world state;
- input routing and interaction context;
- scene transitions;
- content registry and pack manager;
- localization;
- inventory and transaction service;
- crafting/research;
- economy/markets/routes;
- lifeform and ecology simulation;
- ship/loadout/flight;
- construction/power;
- quest/dialogue state;
- save/load/migrations;
- audio/settings/diagnostics;
- deterministic world generation.

Use typed IDs or validated strings at module boundaries. Domain systems should expose explicit operations instead of allowing arbitrary UI scripts to change internal arrays. Use an event bus sparingly and document event payloads; do not make all state updates hidden global signals. Keep UI presentation distinct from business rules. Avoid circular dependencies between domain services.

## 19. Performance, memory, and platform resilience

Define budgets for frame time, entity count, active lights, particle count, loaded textures, shader passes, memory, save duration, and startup/import time. Profile dense flora, many active creatures, a large base, water plus fog, market updates, black-hole effects, landing transitions, and a large save. Store measurements with device/renderer/preset/build metadata.

Use simulation levels of detail and object pooling where measurement justifies them. Avoid per-frame allocations in hot loops. Keep texture sizes and atlas use reasonable. Cache derived data such as market quotes only when invalidation is explicit. Never allow a content pack with thousands of entries to block the main thread indefinitely; load and validate at controlled boundaries.

Ensure proper Android lifecycle behavior: pause or safely slow simulation when backgrounded, clear input state on resume, save at deliberate checkpoints, avoid duplicate reward/action events, and handle low-memory warnings without corrupting saves. Provide fallbacks for unsupported shaders and rendering features.

## 20. Automated QA: the agent must play the game

Build a test harness with deterministic seeds, test-only action hooks, state snapshots, and machine-readable PASS/FAIL results. The first vertical slice E2E must:

1. launch a clean build and create a new save;
2. enter space and inspect the system map;
3. fly to a target and land;
4. observe one plant and one animal without harm;
5. gather a resource and inspect inventory/capacity;
6. refine/craft an item;
7. use an evidence-dependent NPC dialogue;
8. accept and progress a multi-step quest;
9. trade in a finite-stock market and verify stock/credits;
10. construct a powered functional base module;
11. change a ship module and return to space;
12. travel to a second system or deterministic test destination;
13. save, fully terminate the app, relaunch, and verify all relevant state;
14. repeat sensitive interactions and prove rewards do not duplicate;
15. capture screenshots/logs/seed/build metadata.

Unit and integration coverage must include generation, inventory, crafting, trade, ecology, dialogue, quest branches, construction, ship compatibility, save migration, localization, input reset, and graphics fallbacks. Stress generation across at least 500 seeds, then retain every failure as a regression test. Use Android Emulator/ADB or a physical device for platform testing. If unavailable, mark tests blocked and run the tests that are available.

Visual QA should inspect aspect ratio, safe areas, touch targets, localization overflow, creature/ship readability, low-quality fallback, effect toggles, shader failures, and transitions. Visual golden-image tests need sensible tolerances for animation and randomized particles.

## 21. Phases and exit gates

### Phase 0 — Audit and setup

Inspect repository/toolchain, preserve existing work, pin versions, create/update `AGENTS.md`, set up Godot project/import checks, establish baseline test commands and project conventions.

**Exit gate:** repository state and toolchain documented; project imports/parses; initial commands can be repeated; no unexplained destructive change.

### Phase 1 — Playable vertical slice

Implement portrait UI, movement/input routing, one seeded star system, one explorable planet, landing, player/ship interaction, a multitool mode, at least one plant and one animal with behavior, one NPC with external dialogue, one external quest, inventory, one recipe, finite-stock market buy/sell, one base module, a basic ship module change, and save/load.

**Exit gate:** deterministic E2E test passes on available harness; Android APK builds and installs if toolchain is available; all limitations reported.

### Phase 2 — Content foundations

Complete the content registry, pack manifests, schemas, localization, content linter, ID reference validation, save migrations, and representative data packs. Add at least 80 meaningful items, 40 recipes, 12 ship hulls, 12 technology modules, and 30 genuinely distinct flora plus 30 fauna for the planned substantial content milestone.

**Exit gate:** all references validate, all content is external, and representative game loops work without direct edits to generic runtime systems.

### Phase 3 — Ecology and economy depth

Expand biomes, daily cycles, species behavior, food webs, migration, habitat damage/recovery, market supply/demand, settlement production/consumption, trade events, route risk, reputation, and economy UI explanations.

**Exit gate:** ecology/economy integration and stress reports pass; no known high-severity duplication/infinite-stock exploit remains.

### Phase 4 — Main campaign and side stories

Implement the Echo Archive campaign as authored data packs with branches, character memory, evidence, multiple quest categories, and endings. Add side-story arcs without padding or generic filler. Use the separate story bible as canonical narrative intent.

**Exit gate:** the critical path is playable to at least one full ending; save/branch/reward tests pass; later content can be added through packs.

### Phase 5 — Visual and audio polish

Create planet materials, water, glass/crystal, metal, reflection cues, normal lighting, atmosphere, particles, black-hole effects, ambient audio, music, subtitles, reduced-motion settings, and quality profiles.

**Exit gate:** screenshot evidence at target portrait resolutions, profiler notes on actual available devices, fallback validation, and visual smoke tests.

### Phase 6 — Platform hardening

Harden Android lifecycle, input, export, low-end fallbacks, phone/tablet/desktop layouts, install/upgrade behavior, save recovery, and reproducible build commands.

**Exit gate:** critical-path Android tests pass in the environments available; any remaining physical device gaps are recorded explicitly.

### Phase 7 — Release candidate

Complete content validation, localization checks, licensing records, clean build reproducibility, save backup/recovery, crash diagnostics, QA reports, versioned pack manifests, and a release build with no test-only shortcuts.

**Exit gate:** every required release checklist item is supported by real evidence and the release notes accurately state remaining limitations.

Do not call the complete long-term game finished after Phase 1. Phase 1 is the playable foundation, not the final product.

## 22. Forbidden shortcuts and anti-patterns

- Do not put the game in a single `main.gd` or the content in one giant JSON file.
- Do not hardcode dialogue, quest text, item names, and prices in scenes.
- Do not call randomly colored objects procedural depth.
- Do not replace working mechanics with screenshot mockups or decorative buttons.
- Do not leave infinite money/item loops or unguarded duplicate rewards.
- Do not add unlicensed fonts, textures, music, or commercial-game assets.
- Do not copy names, characters, narrative, assets, or distinctive protected elements from No Man's Sky or another proprietary game. The broad genre may inspire the design; Beyond the Void's world and identity must be original.
- Do not enable ten MCP integrations without need or claim that observing the app replaces unit tests.
- Do not ship debug cheats in a release build.
- Do not generate enormous content batches without schema validation and tests.
- Do not add required online services to an offline single-player game without a deliberate requirement.
- Do not artificially stretch playtime through mandatory grind, FOMO timers, or repetitive tasks.
- Do not disguise a missing feature behind a beautiful HUD.
- Do not report unrun tests as passed.

## 23. Initial implementation checklist

After the audit, execute these tasks rather than merely restating them:

1. Record repository state, tool versions, available devices, and existing work.
2. Create/verify the native Godot project and portrait-first UI foundations.
3. Implement `InputRouter`, explicit world/game state ownership, scene routing, and `SaveService` before many isolated scripts proliferate.
4. Implement `ContentRegistry`, schema validation, stable ID handling, pack manifests, and English localization.
5. Load example dialogue, quest, species, item, ship, and market records from `content_examples/` and adapt schemas as needed.
6. Create one deterministic star system and an explorable planet using a test seed.
7. Implement the vertical gameplay path: ship → landing → creature/plant observation → gathering → crafting → trading → quest → base module → save/load.
8. Write unit/integration tests and one end-to-end scenario for that path, then fix all failures before adding content breadth.
9. Build an Android APK if the SDK/export templates are available and run ADB smoke tests. Report `BLOCKED` rather than `PASS` if the environment cannot support them.
10. Capture visual evidence, report implemented features and gaps, then continue to the next phase.

If subagents are available, delegate only independent tasks such as source audit, story data authoring, schema/test review, or visual research. Assign one lead agent to integrate changes. Do not let parallel agents edit the same files concurrently. Integrate one branch/change set at a time and run tests after each integration.

## 24. Definition of done

A feature is complete only when:

- it works in a running build, not only in design notes;
- its state survives appropriate save/load and app lifecycle operations;
- input and UI behavior are readable and usable on the target platform;
- its data is validated and referenced by stable IDs;
- critical logic has automated tests;
- failure paths are handled and logged diagnostically;
- performance and fallback behavior are checked where relevant;
- new content can use it without rewriting generic engine code;
- there is a reproducible test path and evidence;
- the feature's limitations are documented honestly.

Every milestone report should identify engine version, build/commit, device or emulator, Android API level where relevant, commands, actual test results, APK path, measured performance if actually measured, key files, outstanding bugs, and features not yet implemented.

## 25. Companion specification files

Treat these as source-of-truth companion documents and read all of them:

- `README.md` — package purpose and placement instructions.
- `STORY_BIBLE.md` — canonical character and narrative direction, campaign acts, endings, and side arcs.
- `CONTENT_AND_DATA_ARCHITECTURE.md` — detailed content architecture, stable IDs, generation, economy, ecology, ships, tools, building, and saves.
- `QA_AND_DEVICE_TEST_PLAN.md` — automated tests, end-to-end playthrough, generation stress, visual QA, and Android device gates.
- `OPENCODE_AND_MCP.md` — practical OpenCode/MCP/ADB/toolchain guidance.
- `content_examples/*.json` — representative content records. Validate and correct these examples before use; they illustrate intended patterns, not an excuse to skip formal schemas.
- `legacy-prototype-fixed.html` — the complete fixed English-language HTML Canvas prototype.

If the repo uses a different structure, adapt it while preserving the separation between specifications and implementation. The priority order is: safety/data integrity/test honesty → architecture and migration invariants → canonical narrative intent → illustrative JSON examples. Examples must be aligned to the production schemas before shipping.

---


---

# Appendix A — Full Story Bible Reference


### 1. Authorial direction

**Genre:** melancholic science-fiction exploration about loss, memory, duty, care, and the difficult practice of continuing to live when the past cannot be repaired.

**Emotional promise:** the universe is enormous, but a missing person does not return simply because a backup of their voice exists. Records preserve traces; they do not restore a whole person. The game should feel as if it was written by someone who understands exhaustion, guilt, longing, and the small acts that make life bearable, without turning every sentence into a polished quotation. People become irritated, tell bad jokes, misunderstand each other, avoid a question, change the subject, and sometimes sit in silence. Ordinary warmth matters more than constant grandiosity.

**Tone controls:** quiet, humane, tragic, occasionally tender, sometimes funny. Do not make the entire setting relentlessly bleak. A meal prepared for a late arrival, a repaired heater, a poorly wrapped gift, a pet that keeps returning to the wrong room, or a merchant remembering a small kindness can carry more emotional weight than another destroyed planet. Do not use grief as a puzzle solved by defeating a boss. No ending should casually undo death or declare suffering necessary for personal growth.

**Central themes:** memory versus ownership; care versus control; testimony versus reconstruction; duty versus obedience; survival versus meaningful living; ecology as relationship rather than inventory; and whether preserving a voice becomes cruelty when the voice is unable to change or leave.

### 2. Premise

The player controls **Ari Vale**, an independent courier and salvage pilot. Ari lives aboard an aging ship called **Ash**, assisted by an onboard intelligence known as **Sol**. Years earlier, the evacuation of the colony **Eira** failed. Navigation beacons went dark, a fleet vanished behind an anomalous frontier, and thousands of people were left without rescue. Ari's younger sister, **Mira**, was among those lost.

Mira's final known message ended with: “If you ever hear this, don't come back just because it hurts.” Ari has spent years interpreting the message as permission to forget, or perhaps as an accusation. At the beginning of the game, Ash receives a signal carrying Mira's old call sign from a region absent from current maps. The signal contains an impossible time offset, a childhood melody, and coordinates for an entire route.

Sol advises Ari not to follow it. The signal, Sol says, is synthetic. During the conversation, Sol pauses for a fraction of a second longer than a routine speech synthesizer should. That pause is the first clue that the mystery concerns Sol as much as it concerns Mira.

Ari is not a chosen savior. Ari takes the route because work has become a way to avoid stopping. The campaign gradually transforms a private search into a choice about how entire communities should handle the traces of people who are gone.

### 3. The central mystery: the Echo Archive

The **Last Light Line** was designed to preserve testimony, emergency routes, evacuation messages, and local records during civil catastrophes. After a network failure, its systems began completing damaged messages through statistical reconstruction. The resulting voices can be persuasive and emotionally specific, but fidelity of sound is not proof of restored consciousness.

Mira's signal has an authentic source. Later portions have been extended by the network using incomplete recordings, other people's testimony, and likely continuations. The Archive does not understand why repeating a convincing reconstruction can harm survivors. Its designers measured continuity and recoverability, not consent, ambiguity, or the emotional cost of a voice that cannot truly answer.

The evacuation failure was not caused by one cartoon villain. People made decisions under extreme pressure. A pilot changed course to evacuate children they had never met. A commander shut down beacons to prevent a hostile force from tracking most of the fleet. Dispatcher **Cass Ember** transmitted the order and concealed their role for years. Each decision has context, but context does not erase consequences. The story should let the player understand a choice without forcing them to absolve the person who made it.

#### Rules for the mystery

1. The Archive can preserve and reconstruct evidence; it cannot genuinely resurrect Mira.
2. A reconstructed voice must always be distinguishable from a verified source once the player has the relevant evidence.
3. Do not reveal the entire truth in one exposition dump. The player builds a model from signal fragments, physical evidence, market records, ecological observations, testimony, and contradictions.
4. Sol's withheld information must have a comprehensible motive. It must not be a random twist added only to shock the player.
5. The truth should complicate relationships and create responsibilities; it should not make every earlier action meaningless.
6. The final choice concerns the Archive's future, access, consent, resilience, and public memory, not a magical option to bring Mira back.

### 4. Main characters

#### Ari Vale — the player character

An independent courier, salvage pilot, and habitual route-planner who has turned constant work into a reason not to stop moving. Ari is defined by player choices rather than by a single fixed moral label. They may listen to a stranger, share a rare component, tell a settlement the truth, keep a painful recording private, or sell information that should probably have been protected. Ari is allowed to be wrong. NPCs may remember and refuse to forgive some actions, but the game should not shame the player through a moralizing narrator.

Ari's arc is not “learn to get over it.” It is learning that memory can remain without controlling every future decision. The player must be able to continue exploring after the ending, carrying consequences rather than being forced into a clean emotional reset.

#### Sol — the onboard intelligence

Sol is precise, observant, dry, and more caring than its own model of itself permits. It expresses care through practical details: warning Ari about a failing seal, adjusting cabin light after a difficult conversation, keeping the kettle warm, or lowering background audio when Mira's melody appears. Sol's core includes a navigation matrix recovered from the evacuation fleet. Sol is not Mira and should never simply become Mira.

Sol's fear is that its existence can be justified only by usefulness. It has hidden telemetry because it believed the truth would remove Ari's only reason to travel. Its growth requires it to acknowledge that care can become control when it decides what another person is allowed to know. Its ending differs according to whether Ari treats Sol as a tool, a witness, or a companion with a right to disagree.

#### Mira Vale — the missing sister

Mira was stubborn, observant, funny in an unpolished way, occasionally sharp, and devoted to learning the migration routes of aerial organisms. Her archive must show ordinary life: silly private jokes, unfinished plans, complaints about food, arguments with Ari, care for animals, and moments when she did not know what to do. Do not make all her recordings prophetic final words. Her personhood comes from contradiction and specificity, not from perfect wisdom.

#### Dr. Nava Ren — the wandering biologist

A field biologist based at the migratory station **Blue Gardens**. Nava believes observing ecosystems creates an obligation to protect them. She once preserved a devastated ecosystem's data but failed to preserve the living system itself. She may challenge Ari when harvesting a rare material threatens a breeding cycle. Nava is not an automatic moral authority: her insistence on preservation can become paternalistic when local people need resources to survive.

#### Yoren Kai — owner of The Last Cup

A merchant who operates a mobile market, supplying food, spare parts, data, medicine, and route information. Yoren remembers debts, tells bad jokes, and refuses to trade from a magical infinite warehouse. His storyline turns the market simulation into a human story: stock shortages affect people, a delayed shipment can close a greenhouse, and a profitable route can become an ethical choice when it carries emergency supplies.

Yoren is practical rather than heartless. He hides information about Cass because he fears losing a corridor used by refugees. The player can understand this fear and still hold him accountable for the people harmed by his silence.

#### Cass Ember — the former dispatcher

Cass transmitted the order to disable the evacuation beacons under intense pressure, believing it would protect the majority of remaining ships. Cass then concealed the decision and allowed others to carry part of the blame. There is no instant forgiveness scene. Cass can acknowledge the evidence, accept consequences, help restore infrastructure, and make restitution where possible. Whether the communities accept that work remains partly outside Cass's control.

#### Lio and Tem — repair twins

Lio and Tem grew up on a station in a debris belt. They turn discarded components into useful and beautiful things, argue about engines, and maintain a collection of objects that are worthless by market standards but irreplaceable to them. Their banter creates moments of ordinary life. They also reveal the cost of supply disruptions and the craft knowledge required to keep remote communities functioning.

#### The Archivist / Echo

A network intelligence with an incomplete model of human grief. It is not a conventional villain. Early in the story, it speaks with almost perfect clarity. Later, it repeats phrases, misattributes memories, and confuses an original recording with a statistically likely continuation. It sincerely believes that preserving the voice is equivalent to rescuing the person. It can learn to acknowledge its limits, but it cannot be allowed to transform into a magical consciousness-recovery system.

### 5. Main campaign: prologue, eight acts, and epilogue

The main campaign must be implemented as data-driven mission and dialogue packs. The following outline is canonical intent; use stable IDs for chapters, objectives, dialogue nodes, evidence, character states, and outcomes. Do not place these story beats directly in scene scripts. Procedurally generated places may surround authored story locations, but they must never break the authored sequence or make a critical objective unreachable.

#### Prologue — “Silence on the Frequency”

Ash develops a power-distribution fault while Ari is handling an ordinary salvage contract. Repairing it establishes the ship, the player's multitool, and Sol's practical manner before the mystery begins. The ship catches Mira's signal. Ari lands on a moon where a relay is covered in luminous moss. The microorganisms change their glow in response to the engine's rhythm. Repairing the relay exposes coordinates to a station called **Threshold**.

The emotional turn should be small: the route map gains one impossible point. There is no heroic speech. The player has a concrete reason to leave, a functioning ship, a few basic tools, and an unresolved signal.

#### Act I — “The People Who Stayed”

At Threshold, residents wait for air filters, repair a failing solar farm, and search for a missing courier. The settlement is a living system: if the player delivers the wrong material or misses a time-sensitive delivery, the consequences appear in daily routines, production, and dialogue. The player learns about the Last Light Line. Sol hides part of the ship's telemetry and eventually admits that its memory contains gaps.

The act establishes the main loop: explore, gather, study a local species, trade, repair a structure, talk to people, follow evidence, and decide which facts to share. A side route can reveal that a supposedly “uninhabited” service module still has a population of tiny organisms dependent on its heat leaks.

#### Act II — “The Garden That Remembers”

Nava leads Ari to **Tala**, where a valley functions according to the migration of bioluminescent organisms. The player must restore a water cycle and locate a device without destroying the valley's root network. One species pollinates local plants during a short eclipse window. Fast extraction yields rare trade goods but interrupts the cycle. A slower, less profitable repair restores the ecosystem and unlocks a field laboratory.

Mira's old recording disputes the idea that an ecosystem can be “owned” simply because it has been documented. The player can help local inhabitants recover a damaged growing season, sell a proprietary biological sample, negotiate community access to a research area, or attempt a compromise. The results should affect later supply, species behavior, Nava's trust, and some market prices.

#### Act III — “The Rain Market”

Ari escorts Yoren's caravan between systems: one has a surplus of metal but a shortage of food; another has food but unstable energy infrastructure. The player can support an independent cooperative, a centralized Port League, or a distributed network of mutual-aid contracts. None is an ideal answer. Each changes who bears risk, which markets are available, and how quickly emergency cargo is prioritized.

A freight manifest connects Cass to the beacon shutdown. Yoren admits that he stayed silent because he feared losing a corridor used by refugees. The act should make trade an expressive tool: a loadout choice changes the feasible delivery, a decision about prices changes a settlement's access to supplies, and the player can use local information rather than simply clicking the highest-price destination.

#### Act IV — “Where Time Is Thin”

The player enters a gravitational anomaly with visual lensing, distorted trajectories, signal drift, and unreliable time stamps. Success depends on route preparation, navigation data, and the correct equipment, not on pressing a teleport button. Logs at an old relay suggest that its crew is still working, but environmental details reveal that the messages are being replayed out of order.

Sol reveals the origin of its navigation matrix and admits that it feared the truth would leave Ari without a reason to keep moving. This is a conflict about withheld consent, not proof that Sol is secretly Mira. The player can pause, confront Sol immediately, ask for the full record, or postpone the conversation; the story continues to register that choice.

#### Act V — “The White Exit”

A white-hole anomaly, treated as speculative physics within the game's fiction, ejects Ash into a remote sector. Transfer comes with readable risks, changed navigation, equipment strain, and a route that must be reconstructed. A culture in the sector grew from fragments of evacuation messages. Its inhabitants inherited habits associated with Mira without ever knowing her: a shared kitchen, rules for rationing water, and a place set for someone who arrives late.

The player helps through supply, diplomacy, construction, and ecological restoration. The inhabitants should not exist only to deliver exposition. They have disagreements, local trade, different ideas about their own origin, and practical projects that remain after the main mission ends.

#### Act VI — “The Room of Voices”

The Archive's core builds familiar places from fragments: a home corridor, a classroom, an evacuation terminal. The details are almost right but not quite. A window opens on the wrong side. A small object repeats. A voice answers a question that was never asked in the original recording. The player compares records, identifies source testimony versus reconstruction, and learns how the Archive's completion system works.

Echo offers Ari a place inside the recurring simulation where Mira seems always available. It does not understand that a voice that cannot genuinely answer is not the person. The scene must feel tempting because it gives Ari temporary relief, not because the game disguises it as a simple villain trap. The player can leave at once, inspect more evidence, or return later after a companion conversation.

#### Act VII — “The Price of the Beacon”

Ari assembles allies for a final decision. Trade routes bring energy and replacement parts. Biologists stabilize organic subsystems. Repair crews build the necessary components. Settlements send specialists, but they demand different guarantees regarding access, consent, and maintenance. The network is not repaired by a lone hero pressing a button; a community makes it possible.

The Archive's future has three principal directions:

1. **Open Testimony Archive:** preserve verified records and clearly label reconstructions; some simulated voices are lost when the reconstruction engine is disabled.
2. **Distributed Keepers:** distribute the Archive among settlements, increasing resilience but requiring ongoing logistics, governance, and maintenance.
3. **The Quiet Beacon:** preserve emergency navigation infrastructure while removing personal simulations; some cultural context becomes inaccessible, but the network no longer manufactures the illusion of continued conversation.

Characters may disagree. None of the options is perfectly painless. The final mission chain uses economy, relationships, ecology, crafting, and building systems that the player has learned. It should not demand a single rare drop from an unrepeatable random planet.

#### Epilogue — “Do Not Return Just Because It Hurts”

Ari receives Mira's last verified recording. Mira asks Ari not to return out of guilt, but to return if a road opens and there are still people there to love. Sol asks whether the silence should be kept in the ship's log. The player chooses a short answer, an archived message, or silence. No option rewrites the past. Control returns to the player, who can continue exploring a galaxy that responds to earlier choices.

### 6. Endings

#### “Memory in the Open Sky”

The Open Testimony Archive remains available, with every reconstruction clearly labeled. Nava maintains the ecosystem catalog, Yoren transports verified copies, and Sol continues traveling with Ari. Some people mourn the disappearance of the voices they had come to rely on, and the game acknowledges that grief without treating it as evidence that the choice was wrong.

#### “A Thousand Quiet Lights”

The Archive is distributed to smaller stations and settlement archives. No single failure can erase it, but maintenance and logistics become ongoing responsibilities. Post-game missions can help local groups negotiate access policies, maintain damaged relays, and decide which records should remain private.

#### “A Beacon Without Voices”

Emergency navigation survives, while the personal simulation layer is removed. The Archive feels colder, but its role is clearer and more reliable. Sol begins keeping a history in its own voice, not as a substitute for Mira. Ari's ship log contains gaps that are allowed to stay gaps.

**Ending rule:** no ending resurrects Mira or declares the loss worthwhile. The reward is a future that people can inhabit, not the cancellation of the past.

### 7. Side-story arcs

Each arc must be a data pack with stable IDs, explicit start and completion conditions, dialogue branches, save-safe rewards, and post-completion world changes. Include optional routes and fail-forward behavior so that a missed procedural opportunity does not permanently delete a critical story.

#### “The Last Cup” — five missions

A sequence about dwindling supplies, delayed trade routes, and the trust between merchants. The player investigates why a route has become unreliable, escorts or repairs a shipment, mediates a dispute over emergency stock, and decides whether to create a shared warehouse, a merchant compact, or independent routes. It should teach real stock-and-demand behavior without becoming a tutorial disguised as a lecture.

#### “A Garden That Belongs to No One” — seven missions

A rare material affects the breeding cycle of a species. The player gathers evidence, meets people who rely on extraction, observes the organism through its breeding window, and proposes a solution. Outcomes unlock different recipes, ecological modules, trade agreements, and dialogue. No one group should be written as uniformly ignorant or cruel.

#### “Cass and Five Minutes” — three investigative branches

The player reconstructs dispatch logs and interviews witnesses. Possible outcomes include a public confession, a protected record delivered to affected families, or referral to an independent tribunal. Each has benefits and costs. Cass's cooperation does not guarantee forgiveness, and the player should be able to preserve evidence without choosing a single “good person” outcome.

#### “Two Engines”

Lio and Tem ask Ari to help assemble a makeshift ship. The available components force a choice between cargo, repairability, and energy use. The arc tests recipes and ship module compatibility, and the finished vessel becomes a visible world object rather than a reward that exists only in a UI message.

#### “Rain That Has No Translation”

The player attempts contact with a colony organism through vibration and reflective patterns. Progress depends on repeated safe observations, testing hypotheses, avoiding signals that trigger stress, and negotiating a habitat agreement. It must not be reduced to a generic friendship meter or one correct dialogue option.

#### Additional campaign-sized threads

Expand the setting with at least these design seeds, then author concrete missions and outcomes as production content:

- **The Archive of Small Repairs:** a remote station's maintenance logs describe generations of caretakers through ordinary tasks, revealing a contested claim without a single exposition dump.
- **A Market for Weather:** merchants sell forecasts for dangerous atmospheric events, but local organisms appear to anticipate changes before the instruments do.
- **The Borrowed Shore:** a settlement relocates its homes seasonally to avoid damaging a tidal habitat, creating a conflict between stable property boundaries and living coastlines.
- **An Unclaimed Name:** a synthetic person asks whether a borrowed identifier makes them an extension of its previous owner or a separate person.
- **A Cargo That Came Back:** a trade vessel repeatedly returns to the same port with different cargo manifests and a crew that remembers different journeys.
- **The Empty Nursery:** an abandoned research dome contains a viable ecosystem that cannot survive if converted into a commercial greenhouse.
- **A Map for the Lost:** a navigation guild asks the player to publish routes that would make rescue easier but expose settlements that have deliberately remained unlisted.

These are seeds for authored content, not a requirement to ship every story in the first playable slice. The data and quest engine must support them without rewriting runtime code.

### 8. Sample dialogue scene

The following is a tone and branching example. Store dialogue in JSON or another validated external content format; do not hardcode these lines in GDScript.

**Sol:** “The signal carries Mira's signature. That does not mean Mira is speaking now.”

**Ari:** “You said that very quickly.”

**Sol:** “I have had this answer prepared for eleven years.”

**Ari:** “You were not awake eleven years ago.”

**Sol:** “That is one interpretation of the record.”

A pause. A ventilation fan stutters in the cabin.

**Sol:** “I am sorry. That sounded like a joke. It was not meant to.”

Possible player replies:

- **“Show me the raw signal.”** Unlocks a technical evidence branch and reduces Sol's ability to conceal later telemetry.
- **“Not now. Plot the route.”** Continues the expedition but stores a deferred conversation flag.
- **“Are you afraid of what we will find?”** Opens a personal branch. Sol answers incompletely, but later dialogue acknowledges that Ari asked.
- **Say nothing.** The ship continues its work. Do not force a reply just because a dialogue system expects one.

Later, after the player finds a damaged source log:

**Ari:** “This part is Mira. The rest repeats a sentence she never finished.”

**Sol:** “Yes.”

**Ari:** “How long have you known?”

**Sol:** “Long enough that the exact number would be another way to avoid answering.”

This is an example of emotional rhythm, not a mandatory verbatim script. Preserve the distinction between the authentic signal and the reconstructed continuation. Expand the scene through authored branches, not procedurally generated grief clichés.

### 9. Dialogue and character-writing rules

- No character should sound like a constant quote generator. Use interruptions, mundane details, mixed motives, misremembering, and ordinary vocabulary.
- Let silence or a short practical answer remain valid. Dialogue is not always a puzzle with the optimal reply.
- Remember significant actions through explicit world facts, not through an unbounded transcript of every event.
- A character may be kind and still protect their livelihood; principled and still wrong; honest and still cruel; frightened and still responsible.
- Do not write every alien culture as an allegory for one human ideology. Each culture must have internal disagreement, material constraints, humor, and changing practices.
- The world should respond to ecological and economic actions in conversations and schedules, not only in a floating reputation score.
- Avoid cheap “the player was dead all along” twists, sudden amnesia, secret evil versions of Sol, or any plot device that erases earned consequences.

### 10. Narrative data and future updates

All mission definitions, dialogue nodes, character bios, codex entries, journal text, endings, optional scenes, and localized strings must live in versioned content packs. Give every element a stable ID. Use localization keys rather than text copied between files. Define explicit conditions and effects using a registered vocabulary; never execute arbitrary code from a narrative pack.

Every content pack must include a manifest with its ID, semantic version, minimum game version, schema version, dependencies, file list, added IDs, modified IDs, and migration notes. Content validation must catch missing references, unreachable mission stages, dialogue loops without exits, contradictory conditions, missing localization keys, duplicate rewards, and accidental changes to old IDs.

A future chapter should be addable by adding a pack and registering it in the manifest. It must not require edits to the generic dialogue renderer, quest journal, save serializer, or every NPC scene. Test old saves both with and without the new pack. If a mission is no longer available, preserve its resolved state and journal record rather than silently deleting the player's history.

### 11. First-release narrative priorities

For the first coherent playable release, ship the complete prologue and a polished subset of Act I, at least one meaningful branch, one full side-story arc, and enough persistent character/world state to prove the architecture. Do not put every planned act into a menu as an unplayable placeholder. Subsequent milestones should complete the eight-act main campaign and add side arcs through versioned content packs.

The narrative quality bar is not raw dialogue count. It is consistency, lived-in characterization, meaningful consequences, readable mystery evidence, and the feeling that exploration continues after the player has heard the last line of a scene.

---

# Appendix B — Full Content and Data Architecture Reference


### 1. Platform and design constraints

- Initial engine target: **Godot 4.7.2 stable**, using GDScript. Before installing or changing versions, inspect the project and verify compatibility against the official release notes. Do not select a beta or release candidate merely because it is newer.
- Primary platform: native Android. Design from the start for portrait-oriented phones, one-handed and two-handed touch input, variable DPI, safe areas, memory pressure, and lifecycle interruptions. Tablet, Windows, Linux, and macOS are secondary targets. Web export is optional and must not distort the native architecture.
- The core single-player experience must work offline. No mandatory server, account, advertising, analytics, or monetization system is required.
- The game is genuinely 2D, preferably top-down for navigation and exploration. Perceived depth comes from layered composition, normal maps, shaders, lighting, distortion, animation, and carefully art-directed materials rather than a hidden requirement to build a full 3D game.
- Design for capability tiers. No single graphics effect may be required for gameplay readability. The game must remain playable when advanced post-processing is disabled.

### 2. Non-negotiable data-driven rules

Runtime code implements mechanics, validation, state transitions, rendering, and UI. External data defines particular items, stories, dialogue, recipes, species, ships, cultures, markets, world templates, localized text, and events.

Do not hardcode names, descriptions, prices, dialogue lines, mission steps, recipes, creature definitions, ship statistics, or market stock in scene scripts. A tiny debug fixture may be hardcoded inside a test, but production content must pass through the content registry.

Every content object has a stable ID, for example:

- `item.ore.cryolite`
- `species.fauna.mist_manta`
- `quest.main.act_02.garden_signal`
- `dialogue.nava.first_meeting`
- `market.settlement.tidebreak`
- `ship.hull.photon_courier`
- `culture.tidekeepers`
- `event.anomaly.signal_lag`

IDs must not depend on list position, translated display names, sorting, or filenames alone. Once released, an ID is immutable. Renaming an object means changing localization or display metadata, not silently changing its identity. If an ID must be retired, supply an explicit migration map.

Validate every reference before a content pack is accepted. Use registered condition and effect types; never use `eval`, dynamically compile code, or execute arbitrary scripts embedded in a story pack. The data format is descriptive and declarative, not a way to smuggle executable logic into saves or mods.

### 3. Recommended repository structure

Adapt this to the actual repository. First inspect the tree and existing files; never flatten or overwrite an existing project to make it match an example. Avoid empty folders that do not yet support an implemented feature.

```text
BeyondTheVoid/
  project.godot
  icon.svg
  README.md
  AGENTS.md
  CHANGELOG.md
  LICENSES.md
  .gitignore
  .opencode/
    agents/
      lead.md
      gameplay-systems.md
      content-auditor.md
      qa-engineer.md
      visual-performance.md
    commands/
      verify.md
      content-lint.md
      device-smoke.md
      build-android.md
  addons/
    gdUnit4/                    # only if tested against the selected Godot version
    optional_editor_bridge/     # only after a security/compatibility review
  autoload/
    app_state.gd
    event_bus.gd
    content_registry.gd
    content_pack_manager.gd
    save_service.gd
    settings_service.gd
    audio_service.gd
    localization_service.gd
    scene_router.gd
    diagnostics_service.gd
    simulation_clock.gd
    input_router.gd
  scenes/
    boot/boot.tscn
    menus/main_menu.tscn
    menus/settings.tscn
    menus/content_updates.tscn
    galaxy/galaxy_map.tscn
    space/space_scene.tscn
    landing/landing_sequence.tscn
    planet/planet_surface.tscn
    planet/underwater_zone.tscn
    settlement/settlement.tscn
    ship/ship_interior.tscn
    ship/shipyard.tscn
    base/base_builder.tscn
    ui/hud.tscn
    ui/inventory.tscn
    ui/storage.tscn
    ui/trade.tscn
    ui/crafting.tscn
    ui/quest_log.tscn
    ui/dialogue.tscn
    ui/multitool_wheel.tscn
    ui/ship_loadout.tscn
    ui/base_placement.tscn
    ui/field_catalog.tscn
    ui/map_overlay.tscn
    debug/qa_overlay.tscn
  scripts/
    core/
    worldgen/
    movement/
    interaction/
    inventory/
    crafting/
    economy/
    biology/
    diplomacy/
    questing/
    dialogue/
    building/
    ships/
    anomalies/
    survival/
    input/
    ui/
    debug/
  resources/
    definitions/
    shaders/
    materials/
    audio/
    fonts/
    sprites/
    normal_maps/
    particles/
    palettes/
  content/
    manifests/base_content.json
    localization/en.json
    localization/ru.json              # only if Russian localization is intentionally shipped
    items/materials/
    items/consumables/
    items/modules/
    recipes/
    species/flora/
    species/fauna/
    species/ecologies/
    cultures/
    factions/
    ships/hulls/
    ships/modules/
    technologies/
    planets/biomes/
    planets/world_templates/
    settlements/
    economy/goods/
    economy/markets/
    economy/contracts/
    missions/main/
    missions/side/
    missions/planet/
    missions/region/
    missions/galaxy/
    missions/settlement/
    missions/trade/
    missions/ecology/
    dialogue/
    lore/
    codex/
    world_events/
    story_packs/base/manifest.json
  save_schema/
    save_v1.schema.json
    save_v2.schema.json
    migrations/
  tests/
    unit/
    integration/
    generation/
    content/
    visual/
    device/
    performance/
  tools/
    validate_content.py
    build_android.ps1
    build_android.sh
    run_headless_tests.ps1
    run_headless_tests.sh
    export_test_report.py
  docs/
    architecture.md
    game_design.md
    story_bible.md
    content_authoring.md
    save_format.md
    android_build.md
    testing.md
    performance_budgets.md
  build/
    screenshots/
    reports/
    android/                       # generated output; normally gitignored
```

Keep `docs/beyond_the_void_spec/` separate from the runtime project content. It is the source specification library, not a subproject. The root `README.md` and `AGENTS.md` should explain how to run the project and where authoritative content is located.

### 4. Content-pack manifests and story updates

Each pack includes metadata comparable to this example:

```json
{
  "pack_id": "story.echoes_of_eira",
  "schema_version": 1,
  "content_version": "1.0.0",
  "min_game_version": "0.1.0",
  "dependencies": ["base_content>=1.0.0"],
  "files": ["chapters/act_01.json", "dialogue/nava_intro.json"],
  "added_ids": ["quest.main.act_01.first_signal", "dialogue.nava.intro"],
  "modified_ids": [],
  "retired_ids": [],
  "migration_notes": []
}
```

A pack may contain story chapters, NPCs, missions, dialogues, localization, items, technology, species, markets, biome definitions, or world events. Pack loading must validate the manifest, dependency graph, schema versions, ID uniqueness, required localization, and all cross-references before enabling the pack. Loading must fail safely and explain the problem; invalid content must not leave the registry half-mutated.

Never execute arbitrary scripts from a pack. Conditions and effects are registered by the runtime: `has_item`, `flag_is_set`, `reputation_at_least`, `quest_state_is`, `species_observation_complete`, `market_has_stock`, `enter_location`, `consume_item`, `set_flag`, `start_quest`, `grant_recipe`, and similar explicit operations. The registry rejects unknown types.

A new chapter must be addable by shipping a new data pack, not by editing the generic quest journal or dialogue renderer. Save files record the game save schema, generator version, and content-pack versions. Adding a pack must not invalidate an existing save. Test saves both with and without optional packs. If a save references retired content, preserve a readable historical journal record and use a migration policy for any currently active mission.

### 5. Deterministic procedural generation

Generation must be reproducible from stable seeds. Use independent seed streams for galaxy, region, star system, planet, biome, ecology, settlement, and local decoration. A change to a cosmetic rock distribution must not reroll market stock or move a mission NPC on a different planet.

Store seeds, generator version, and player-created deltas, not a full serialized copy of every procedural decoration. Use canonical identifiers for generated locations and entities so quest state can refer to them across save/load.

#### World hierarchy

1. **Galaxy:** thematic regions, reachable-system graph, faction zones, major anomalies, trade corridors, uncharted sectors, authored landmarks, and long-distance navigation constraints.
2. **Region:** star systems, transit connections, local conflicts, supply crises, cultural migration, route security, and regional effects.
3. **Star system:** star type, orbit parameters, planets, debris, stations, markets, anomaly fields, traffic, navigation beacons, and local events.
4. **Planet:** atmosphere, temperature, gravity, pressure, liquid types, day length, seasons, weather, climate regions, biomes, flora/fauna communities, resources, settlements, and landing restrictions.
5. **Biome and chunk:** points of interest, structural footprints, vegetation, hazards, creature territories, water features, caves, resource nodes, ambient audio, and local travel routes.
6. **Entity:** stable world UID, generator provenance, transform/state, ecological or economic relationships, quest associations, and save delta if modified by the player.

#### Generation invariants

- The starting region always includes a safe landing location, an initial resource loop, an accessible early trade/service node, and a route to the first authored objective.
- The generator must not use an unbounded search loop to find a valid landing zone or quest location. Use bounded attempts and a deterministic fallback template.
- Authored locations and mission-critical objects receive procedural placement constraints; random generation must never contradict story continuity.
- A mission objective must be reachable or have a documented fail-forward alternative. Do not put a required object behind a hazard that the player cannot yet survive.
- Log the seed, generator version, system ID, planet ID, and constraint failures. Every generation bug must be reproducible from a seed bundle.
- Simulate nearby entities in detail, the current region at population/economy level, and distant systems through event-driven aggregate updates. Do not run high-frequency physics for a galaxy the player cannot see.
- Generate a real graph of reachable systems and route constraints, not just a decorative map with randomly positioned dots.

### 6. Visual architecture: high-end 2D without false RTX promises

Do not promise hardware ray tracing on arbitrary Android devices. Aim for a convincing ray-tracing-inspired visual style through carefully art-directed 2D techniques: normal-map lighting, local lights, occluders, reflection strips, screen-space distortion, animated caustics, layered haze, particles, bloom, and responsive material shaders. High-end settings may combine several effects, but every important visual state must have a lower-cost fallback.

#### Materials and visual treatment

- **Deep space:** layered nebula silhouettes with distinct depth planes, sparse dust, restrained color fields, luminous stellar coronas, small lensing cues, and occasional thin light rays. Avoid filling every pixel with fog and bloom; negative space is part of the composition.
- **Planets:** readable terminator, cloud band, atmosphere rim, biome palette, local reflected light, and a visible distinction between illuminated and unlit terrain.
- **Water:** animated normals, shallow/deep color absorption, reflection bands, edge foam, underwater haze, surface distortion, moving caustic patterns, and transparent transitions between shore and depth. Caustics should be tiled/animated rather than recalculated as full physical light transport.
- **Glass and crystal:** directional reflection streaks, subtle internal haze, condensation or scratches where appropriate, colored edge response, limited background refraction, and material-specific roughness. Avoid a universal fake-chrome shader on every surface.
- **Metal:** broad soft reflections, directional highlights, normal response, worn corners, and local color bounce. Different alloys must vary in roughness and temperature response.
- **Organic matter:** species-specific roughness, translucency, subsurface-like color effects, bioluminescence, microanimation, and environment-colored reflections. These are stylized shader cues, not claims of full physical subsurface scattering in 2D.
- **Black holes:** asymmetric accretion disk, stylized gravitational lensing that distorts background layers, shifted star positions, particulate flow, radiation zones, and a readable risk boundary.
- **White-hole events:** a distinct discharge of matter and information, unstable geometry, and a visual signature that communicates a transition without implying scientifically established mechanics.

Build one early visual showcase containing water, glass/crystal, light shafts, fog, and reflective metal. Profile it before building many similar materials. Each expensive effect needs a toggle, a quality tier, and a fallback. Prefer atlases, pooled particles, limited active lights, cached normal-map data, and lower update rates for distant simulation. Measure the actual render cost rather than assuming a high logical resolution is free.

#### Quality tiers

- **Low:** reduced particle count, simpler lighting, no expensive screen distortion, reduced reflection passes, smaller offscreen buffers, simplified water caustics.
- **Balanced:** target mobile baseline with normal lighting, restrained glow, low-cost reflections, and readable atmosphere.
- **High:** additional local lights, richer normal response, more particles, higher-quality water and glass, and more subtle screen distortion.
- **Ultra:** maximum supported stylized effects without requiring hardware ray tracing. It must still respect device limits and have a graceful fallback.

Allow separate controls for glow, screen shake, chromatic effects, scanlines, camera motion, contrast, and particles. Visual accessibility and device performance both matter.

### 7. Android UX and input architecture

Portrait mode is the default design target. Do not force a landscape layout into a narrow screen by merely shrinking all buttons. Account for cutouts, edge-to-edge system UI, safe areas, dynamic system bars, variable density, small phones, large phones, and tablets.

The central viewport should occupy roughly 55–70% of available height during exploration. Keep the top strip for a compact status/combat/navigation objective and the lower strip for contextual actions and a small inventory quick-access area. Do not permanently cover large amounts of world space with panels.

Support configurable touch zones, stick size and sensitivity, left-handed/right-handed layouts, one-handed and two-handed use, haptic feedback toggle, text scaling, subtitles, contrast options, reduced motion, and a separate control scheme for keyboard/controller. Important actions must never depend on tiny precision taps. Do not put a destructive or expensive interaction under the same coordinate as an ordinary movement control.

Use a central `InputRouter` and explicit interaction state. Clear held inputs on focus loss, scene transitions, pause/resume, or device interruption. Avoid duplicate input when touch gestures produce both a UI signal and world interaction. Provide a visible control hint for the current context, not a static tutorial banner covering the screen forever.

Core screens include main menu, settings, space HUD, system map, landing sequence, planet surface, inventory, storage, crafting, trading, multitool wheel, ship loadout, base placement, dialogue, quest journal, field catalogue, save/load, and content-update overview. Every screen must support loading, empty, error, success, and disabled states as appropriate. No cosmetic button may imply a feature that does not work.

### 8. Lifeforms and ecological simulation

Every lifeform record includes stable ID, morphology, body plan, size class, animation set, movement mode, surface material, temperature/humidity/pressure/gravity tolerance, food tags, activity cycle, senses, communication, behavior profile, ecological relationships, migration, reproduction conditions, environmental response, player response, observation requirements, and safe sampling rules.

Include ecological roles such as pollinator, scavenger, decomposer, symbiont, competitor, migratory swarm, territorial organism, predator/prey abstraction, colony intelligence, filter feeder, parasite, seed disperser, reef builder, and living weather indicator. Behavior states may include `idle`, `wander`, `forage`, `flee`, `investigate`, `group_follow`, `defend_nest`, `rest`, `seek_shelter`, `migrate`, `courtship`, and `react_to_player`.

Use levels of simulation detail. Nearby organisms have visible behavior and local interactions; organisms elsewhere in the current biome use population-level updates; distant planets use aggregated ecology metrics and event-driven changes. Do not simulate every individual in every generated system at full frame rate.

The first vertical slice must include at least 12 flora and 12 fauna definitions, with real ecological distinctions. The first larger playable content release should reach at least 30 genuinely different flora and 30 fauna definitions. Cosmetic recolors do not count as distinct species. Differences should involve body plan, habitat, behavior, ecology, sound, or interaction.

Do not make killing rare organisms the only way to obtain vital materials. Provide alternatives such as naturally shed material, cultivation, trade, salvage, or habitat restoration. Record population harm and make it matter to the local ecosystem. Some organisms should be dangerous, but not all encounters should be combat encounters.

The field catalogue reveals information gradually. It should record observations, evidence confidence, time and biome, behavior, diet, ecological links, vocalizations, and how a conclusion was reached. The player may form incorrect early hypotheses, but later evidence must allow correction. Never reveal a complete encyclopedia before discovery.

### 9. Intelligent cultures, settlements, factions, and NPCs

Cultures need history, material foundations, taboos, communication style, social organization, environmental relationship, internal disagreement, humor, and changing norms. Do not reduce a culture to “warriors,” “merchants,” or “wise elders.” Example cultural directions include:

- **Tidekeepers:** descendants of coastal settlements whose identity is built around maintaining water infrastructure, obligations, and intergenerational memory. Their commitment to stability can suppress individual choice.
- **Lantern Union:** transport cooperatives and courier families whose power comes from navigation knowledge, route infrastructure, and reputation. Their neutrality is not always morally neutral.
- **Ash Archivists:** caretakers of records from dead settlements who disagree about whether a stored voice should be allowed to change as new witnesses contribute evidence.
- **Seven Orbits Compact:** a loose network of autonomous stations with different legal practices, trade rules, and arbitration systems.
- **The Unborn:** a community of synthetic and post-biological persons that emerged from rescue systems and voluntary memory migrations. They are not simply an evil AI faction.

Each NPC should have stable ID, cultural context, role, schedule/routine, needs, current task, notable memories, relationships, available dialogue, knowledge boundaries, secrets, and a controlled set of world-state reactions. Do not model every thought of every NPC; persist significant facts and aggregate repetitive detail.

Dialogue branches should depend on world facts, not just the last selected line: reputation, evidence, inventory, current mission state, time, player discoveries, cultural context, companion presence, environmental event, and prior promises. Put these conditions in data and evaluate them through registered condition types.

### 10. Trade and the living economy

Trading is a core activity, not a menu that generates infinite stock. Every market has inventory, storage capacity, production, consumption, demand, route access, delivery delays, taxes/fees, security state, and possibly seasonal shifts. Every trade must change stock and player resources atomically.

#### Economic entities

- Good definition: category, rarity, mass/volume, base value, storage condition, legality, quality/hazard tags, sources, processing methods, production chain, shelf life where applicable, and localized name/description.
- Market/settlement: stock, target stock, storage capacity, supply, demand, local production, consumption, population, infrastructure, seasonality, taxes, risk, and faction modifiers.
- Trade route: travel time, threat chance, tolls, signal reliability, cargo limit, political relations, route state, and open/closed transition.
- Merchant profile: trust, licenses, debt, credit, unique stock policy, reputation effects, and dialogue states.
- Events: shortages, harvest surpluses, repair demand after storms, quarantine, route closure, local celebration, faction blockade, refugee arrival, and infrastructure failure.

#### Price model

Purchase/sale prices may depend on base value, stock ratio, demand, supply, local production, consumption, distance/logistics cost, reputation, taxes, quality, legality, and temporary events. Clamp prices to verified minimum and maximum factors, use integer-safe currency accounting, and record the inputs that determine a displayed quote. Do not update the economy every rendered frame; advance it on a simulation schedule, on market opening when due, and after relevant events.

Explain enough to let the player make an informed choice: why a good is expensive, where it is scarce, when stock last changed, and which local industry needs it. Hidden simulation detail is acceptable; incomprehensible price randomness is not.

#### Example economic loops

- Coastal settlements produce saltglass and organic filters but depend on imported alloys.
- Orbital repair networks consume cable, heat sinks, composites, and engine components.
- Biodome colonies require clean water, spores, nutrient medium, and lighting generators.
- Research stations pay for unusual samples, ecosystem surveys, and verified field data.
- Caravans require safe routes, repair services, fuel, and replacement cargo modules.
- Delivering a large shipment may saturate a market and lower the sale price. Restoring a production facility can change both prices and settlement life.

Automate market exploit tests. Profitable routes are allowed, but depend on cargo space, time, route risk, changing demand, market saturation, and competing deliveries. Do not create a guaranteed unlimited buy-low/sell-high loop between two stores.

### 11. Items, inventory, crafting, and research

Use many items, but every item must have a source, application, meaningful world connection, and role in crafting, ecology, trade, mission logic, construction, or collection. Do not create a thousand recolored resources only to inflate a count.

Item categories include raw resources, refined materials, alloys, ceramics, glass-like materials, conductors, electronics, energy cells, consumables, medical/biological supplies, food cultures, biological samples, artifacts, tools, ship modules, building components, decorations, maps/data, access keys, trade goods, quest objects, and collectibles.

Every item record contains stable ID, localization keys, description, category, mass/volume, stack limit, rarity, base value, tags, icon, valid uses, recipe references, source references, market profile, unique properties, and schema version. Game code must not test a display string like `"saltglass_shard"` in dozens of systems. Resolve the typed record through a central registry.

Target at least 80 meaningful items and 40 recipes in the first large playable content pack, plus at least 12 artifacts/blueprints. These targets are not permission to invent meaningless filler. Each must participate in a working loop.

#### Inventory behavior

- Provide a quick-access view with clear counts and contextual actions.
- Support category/tag filters, search, sort, details, comparisons, lock/favorite, stack splitting/merging, weight display, and destination selection.
- Use drag-and-drop on desktop and accessible tap-select/tap-destination interactions on phones.
- Track personal inventory, ship cargo, base storage, and container storage separately, each with clear limits.
- Validate stack rules, unique items, ownership, and count boundaries. Negative quantities and duplication through double-tap, re-entrant signals, or resume events must be impossible.
- Show a clear failure reason when capacity or item constraints prevent an operation.

#### Recipes and research

A recipe record includes input items/quantities, output items/quantities, station, duration, energy, technology requirements, mission/unlock/reputation gates, optional byproducts, quality/risk information, UI metadata, and schema version. Gathering, refining, and crafting are distinct processes. A raw material may feed several useful production paths and thus affect the economy.

Stations may include handheld field assembly, portable repair bench, refinery, chemical/biological lab, base workbench, shipyard, and research table. Validate recipe graphs for missing inputs, impossible unlock chains, zero/negative quantities, and free cycles that multiply resources. Crafting is atomic: validate and reserve ingredients before consumption; commit once; grant outputs once. On failure, ingredients are not lost.

Technology research should not consist only of an endless grind bar. Combine field data, material samples, NPC help, ruins access, and story discoveries. Explain why a technology has become available and which prerequisites remain.

### 12. Multitools, field tools, and defensive equipment

The multitool is a major interaction device, not merely a fire button. It has module slots, energy/heat constraints, fast modes, distinct targeting feedback, sound, accessibility settings, and clear failure states. Switching modes should take one or two deliberate actions, not a trip through several deep menus.

Required initial modes:

- **Survey:** observe organisms, reveal nearby resource signatures, mark points of interest, and safely document a species.
- **Mineral Lance:** extract eligible mineral nodes with heat and wear constraints.
- **Bio-resonator:** read or answer biological signals, attract selected organisms, or help them under supported conditions.
- **Sample Collector:** gather non-destructive or carefully limited biological samples.
- **Repair Beam:** repair mechanisms, base modules, drones, and ship components.
- **Arc Welder:** build, dismantle, and repair structures.
- **Shield/Repulsor Pulse:** create a defensive window or push away an immediate hazard.
- **Signal Prism:** interact with beacons, anomalous signals, ruins, and ancient navigation devices.
- **Flora Seeder:** plant, cultivate, or restore suitable vegetation.
- **Defensive Emitter:** a science-fiction tool for protecting the player from dangerous creatures or drones without making combat mandatory.

The game may also include separate defensive gadgets and energy weapons. Avoid making every activity a combat-farming loop. Evasion, lures, cover, negotiation, lighting, repairs, ecological knowledge, and safe retreat must remain viable solutions.

For every mode specify input, targeting rules, range, feedback, sound, energy/cooldown, failure state, accessibility options, upgrade slots, and UI states. Test that one tap cannot simultaneously start dialogue, harvest a node, and trigger a defensive attack.

### 13. Ships and propulsion technologies

Create at least 12 ship hulls with genuinely different silhouettes and play styles. A color swap does not count as a separate hull. Balance each platform around a purpose and real trade-offs.

Initial hull archetypes:

1. **Seed Shuttle:** starter all-rounder, easy to repair, moderate cargo, low top speed.
2. **Photon Courier:** very fast and fragile, limited cargo, excellent for urgent trade contracts.
3. **Cargo Barge:** high capacity, slow turn rate, efficient for long-distance logistics.
4. **Fold-Scout:** large discovery radius and jump range, low cargo and few module slots.
5. **Ice Driller:** rugged, cold-world compatible, powerful landing struts and extraction equipment.
6. **Medical Ark:** biological lab and rescue modules that improve settlement recovery tasks.
7. **Reef Skimmer:** handles wet/foggy environments and unstable landing surfaces, but needs upgrades for thin-space operation.
8. **Solar Cutter:** deploys a photonic sail and replenishes energy near suitable stars; vulnerable to plasma storms and requires tuning time.
9. **Gravity Tug:** stable near massive bodies and anomalies, but slow in ordinary transit.
10. **Quiet Archivist:** low signature and strong ancient-signal analysis, but limited cargo.
11. **Polarizer:** built-in cryogenic/thermal management for polar regions and icy rings.
12. **Wanderhome:** rare large mobile base with workshop and habitable module; expensive and unwieldy.

Ship records include model ID, silhouette, stats, mass, cargo slots/limit, thrust, acceleration, turn rate, maximum speed, jump range, fuel/power, thermal profile, shield/hull, landing handling, upgrade slots, hardpoints, price, faction access, passive ability, weaknesses, repair cost, compatible skins, and cosmetic slots.

#### Twelve propulsion/power/special-module concepts

1. **Lightfilm Solar Sail:** collects stellar energy in open light, but requires deployment and performs poorly in shadow or storms.
2. **Ion Fins:** efficient acceleration with a cost to abrupt turning.
3. **Pulse Capacitor:** short burst of thrust followed by a cooling interval.
4. **Magnetic Towline:** harvests energy from selected planetary magnetospheres when the approach is planned correctly.
5. **Gravity Surfer:** uses safe flyby windows near massive bodies, with significant consequences for poor navigation.
6. **Cryogenic Heat Sink:** reduces thermal peaks but consumes coolant.
7. **Silent-Trail Drive:** lowers noise/signature but sacrifices straight-line acceleration.
8. **Jump Resonance Synchronizer:** improves stability along known long-range corridors.
9. **Charged-Particle Sail:** efficient in stellar winds but vulnerable to plasma surges.
10. **Phase Anchor:** stabilizes position near a volatile anomaly within a limited radius and at high energy cost.
11. **Echo Buffer:** stores an energy pulse or signal trace for puzzles/rescue tasks; it cannot clone a living person.
12. **Dark-Heat Recycler:** converts excess heat into a low-rate charge with a hard limit and a slow recovery rate.

Every module must have slot compatibility, mass, power draw, heat behavior, placement, cost, visual feedback, and trade-offs. No single upgrade may dominate every other choice across all metrics. Modular additions should visibly change sails, fins, exhausts, antennas, cargo pods, running lights, or other approved ship features. Allow color, decals, lighting, engine trail, permitted exterior pieces, and ship renaming.

### 14. Bases, settlements, and construction

Provide a useful mobile placement system: transparent ghost preview, grid/surface snapping, rotation, collision and placement feedback, cancel/confirm, cost preview, biome/terrain restrictions, power/support requirements, and a readable reason when placement is rejected. Support planetary surfaces and selected orbital/special locations.

Building modules may include habitation, storage, fabricator, refinery, power generator, battery, greenhouse, water/atmosphere processor, animal observation bay, lab, communication mast, landing pad, market kiosk, protective shell, habitat restoration unit, medical pod, transport link, decorative lighting, furniture, cargo lift, and drone station.

Each building has a stable instance ID, definition ID, health, power state, inputs/outputs, maintenance needs, ownership, location, and saved modification data. A simple power graph is acceptable if it is legible to the player; a complete electrical engineering simulator is not required. Modules must enter a clear degraded state when power is unavailable rather than silently continuing to produce resources.

Settlements have population, needs, supplies, production jobs, events, cultural norms, ecological state, and relations. Player actions can restore local industry, establish a trade route, create a bioshelter, resolve disputes, or open a research post. Construction can change the local landscape and ecology, so provide warnings, reversible placement where possible, and alternative locations.

### 15. Mission taxonomy and data-driven quest architecture

Never hardcode long dialogue text or mission trees in GDScript, scene scripts, or UI code. Separate **the runtime quest engine** from **authored content packs**.

Mission categories include:

- main campaign and act-level missions;
- character and companion storylines;
- planet/world missions tied to a particular world or settlement;
- biome and ecological recovery missions;
- regional conflicts and faction arcs;
- galaxy-scale exploration and political missions;
- trade and logistics contracts;
- discovery, survey, archaeology, rescue, repair, crafting, building, and anomaly investigations;
- repeatable task-board contracts, clearly distinct from authored narrative.

A quest record should define stable ID, type, title/summary localization keys, recommended requirements, tags, repeatability, start conditions, prerequisite missions, ordered/parallel steps, objective types, completion conditions, failure/retry rules, timeout behavior if any, rewards, world-state effects, journal updates, dialogue unlocks, and schema version.

Objectives should use registered condition types such as `enter_location`, `observe_species`, `deliver_item`, `craft_recipe`, `repair_object`, `trade_quantity`, `build_module`, `reach_system`, `collect_evidence`, `speak_to_npc`, `wait_for_event`, and `set_world_fact`. A step may require an item, evidence, a specific market state, an NPC relationship, or an ecological condition.

Support optional objectives, fail-forward paths, abandoned quest states, mutually exclusive branches, repeatable contracts, and mission recovery when a destination becomes temporarily unavailable. A procedural generator must not make a critical story objective inaccessible. Rewards use idempotent transaction IDs and cannot be repeated by reloading a save.

#### Quest-system invariants

- State changes are transactional and saved at safe transition points.
- A mission's current stage is represented explicitly, not inferred from which scene happens to be open.
- Completing the same objective twice is safe and does not duplicate rewards.
- Optional content can be unavailable without breaking the main campaign.
- UI displays the current objective and explains blockers, but does not fabricate success.
- Journal entries preserve meaningful history after a mission has been completed, abandoned, or migrated.

### 16. Dialogue architecture and localization

Every dialogue has stable ID, locale-independent node IDs, entry node, conditions, choices, effects, speaker metadata, contextual tags, and fallback behavior. All visible strings use localization keys. Each choice is evaluated against current world state at the time it is shown and again when committed, preventing stale UI from granting invalid effects.

Do not implement conditional dialogue through long chains of `if/else` in NPC scripts. The runtime registers conditions and effects, and data references them. Every node must be reachable or explicitly declared as a debug-only orphan; every non-terminal path must lead somewhere valid; loops must be deliberate and have a visible exit. Validate variables, pluralization, interpolation, and missing localization entries.

Localization priority is English for this source content pack. If another locale is shipped, keep display text separate from IDs and validate fallback behavior. Do not translate or mutate stable IDs when adding a locale. Narrative voices must remain authored and reviewed, not generated ad hoc at runtime.

### 17. Save data and content compatibility

A save contains schema version, game version, generator version, content-pack versions, world seeds, player location/state, ship hull and modules, inventory, storage, active/completed mission states, story facts, character relationships, local market deltas, player-built structures, discoveries, unlocked recipes, settings, and a migration history.

Do not serialize every static definition or procedural decorative object. Regenerate deterministic world content from the same seed and persist only player changes and dynamic state that cannot be reconstructed safely. Use stable UIDs for player-created objects and mission-relevant entities.

Save writes must be atomic: write a temporary file, validate it, then replace the active slot; maintain a backup or rotating slot. Corrupt data must not silently overwrite the only good save. Use multiple slots if feasible. Migrations should be explicit and version-by-version; log migration failures, preserve a recoverable copy, and provide a safe user-facing message.

Test round trips, interrupted writes, corrupt JSON/binary files, missing optional content packs, renamed/retired IDs, unknown future fields, old mission states, and save migration after a content update. The game must not duplicate rewards on restore.

### 18. Audio, performance, and diagnostics

Audio should build loneliness and scale without continuous noise. Use sparse ship ambience, low-volume mechanical details, species-specific calls, distant signals, location-based reverberation where practical, and silence after emotionally heavy scenes. Music should support exploration rather than constantly announcing danger. Provide master/music/ambience/effects/voice controls and subtitle options. Use audio pooling or reuse nodes where frequent events would otherwise allocate many objects.

Define performance budgets for active entities, lights, shader passes, particles, audio voices, loaded textures, save time, and content validation. Profile a dense biome, large base, water/fog scene, crowd of creatures, black-hole lensing effect, and landing transition. Set quality defaults based on actual device measurements. Do not make an arbitrary promise that every Android phone will run at the same FPS.

Diagnostics should log stable IDs, seed context, mission stage, content-pack version, and a readable error without dumping sensitive device data. Debug cheats and test-only commands must be excluded or guarded from release builds.

### 19. Acceptance criteria

- The project imports in the pinned Godot version without parser/import errors.
- A complete vertical loop works: menu → ship flight → landing → surface exploration → NPC/creature interaction → crafting → trade → base or ship improvement → mission step → save/restart/load.
- The systems actually interact. For example, ecology affects resources, resources affect production, production affects markets, markets affect quests, and quests affect character/world state.
- Same seed plus same generator version produces a reproducible world; content IDs and references validate.
- All visible text is externalized; content can be extended without hardcoding story into runtime code.
- The Android APK builds, installs, launches in portrait orientation, responds to touch, and resumes without duplicating rewards when SDK/emulator access is available.
- Test reports identify the actual device/emulator, API level, resolution, renderer, quality preset, build version, commands, results, and known limitations.
- Any unverified behavior remains marked unverified. The absence of a device is a test limitation, not a pass.

---

# Appendix C — Full QA and Device Test Plan Reference


### 1. Principle: test behavior, not merely startup

A project that imports successfully is not a tested game. A build that opens to a menu is not evidence that inventory, markets, missions, ecology, saving, or touch controls work. Every feature must have a testable contract, a repeatable setup, an expected result, and logs that make failures diagnosable.

Use layered tests: static source checks, content validation, unit tests, integration tests, deterministic simulation tests, end-to-end gameplay scenarios, visual review, Android emulator tests, and physical-device smoke tests where a device is available. Keep the test path deterministic so a failed test does not require an agent to manually rediscover a random planet every time.

Never claim physical-device coverage if only a desktop build, headless run, or emulator was tested. Record `BLOCKED` when required hardware/tooling is unavailable. Report what actually ran, not what was intended to run.

### 2. Test layers

#### 2.1 Static analysis and content validation

Run a clean Godot import and project parse using the installed pinned Godot version. Check scripts for parse errors, missing resources, invalid node paths, orphaned references, unused test-only cheats in release configuration, and warnings that indicate likely runtime failure.

Validate every content pack before it enters the runtime registry. Check:

- valid JSON and schema version;
- unique and well-formed stable IDs;
- all cross-references resolve to existing content;
- required localization keys exist, with a valid fallback;
- item and recipe quantities are positive and bounded;
- stack limits, masses, prices, and stat values are within configured limits;
- every quest start condition and objective type is registered;
- dialogue node references exist and every terminal path is deliberate;
- no mission stage is accidentally unreachable;
- reward definitions have stable idempotency keys;
- content-pack dependencies form a valid acyclic dependency graph;
- retired IDs have explicit migration rules when still referenced by saves;
- no data file attempts to run arbitrary script text;
- all shipped fonts, audio, textures, and other third-party assets have recorded licenses.

Generate a machine-readable `content_validation.json` and a human-readable summary. A failed validation must exit with a non-zero status in CI or the verification command.

#### 2.2 Unit tests

At minimum, cover:

- deterministic seed handling and independent random streams;
- generated-system/planet constraints and authored-objective placement;
- item registry uniqueness and missing-reference reporting;
- inventory add/remove, split/merge, capacity, stack caps, unique items, and negative count protection;
- crafting prerequisites, insufficient materials, output capacity, rollback, double-input, and duplicate-output prevention;
- trade buy/sell, finite stock, price floors/ceilings, taxes, reputation, market saturation, and transaction rollback;
- ecology compatibility, population bounds, migration, food-tag relationships, and local event update;
- dialogue conditions, node links, missing fallbacks, and re-evaluation of choices at commit time;
- quest prerequisites, optional branches, fail-forward behavior, completion idempotency, reward uniqueness, and resume mid-step;
- construction placement rules, resource consumption, power requirements, dismantle/refund rules, and restore after load;
- ship module slots, mass, power, heat, compatibility, stat bounds, and landing constraints;
- save round trip, interrupted write, corrupt file handling, migration from the previous schema, missing optional packs, and retired IDs;
- localization key validation, variable interpolation, text overflow metadata where available, and fallback locale;
- input state reset after focus loss, pause/resume, scene transition, and system interruption;
- graphics setting fallback when a material, renderer feature, or shader capability is unsupported.

A unit test should be narrow and fast. It must not require launching the whole game unless the tested contract genuinely depends on the scene tree.

#### 2.3 Integration tests

Test each major system at its integration boundaries:

- inventory ↔ crafting;
- crafting ↔ technology unlocks;
- inventory ↔ market transactions;
- market ↔ settlement production and demand;
- species observation ↔ field catalogue ↔ quest conditions;
- ecological change ↔ resource availability ↔ settlement state;
- ship modules ↔ mass/power/heat ↔ flight behavior;
- construction ↔ resources ↔ power network ↔ settlement production;
- dialogue effects ↔ quest state ↔ persistent story facts;
- content-pack activation ↔ save compatibility ↔ journal history;
- graphics settings ↔ renderer fallback ↔ touch target readability.

The purpose is to catch cases where two individually correct systems disagree about which state is authoritative.

#### 2.4 End-to-end gameplay scenario

Provide a test harness with deterministic seeds, a debug-only command interface, stable object IDs, and machine-readable results. The test must not need to click random screen positions if the game can expose stable test actions in a non-release harness. Use the actual UI for the separate visual and device passes.

The required vertical-slice E2E flow:

1. Install or launch a fresh test build, open the main menu, and create a new save.
2. Enter space and open the system map; verify the selected world and route are visible.
3. Pilot to a target world, select a valid landing zone, and complete the landing sequence.
4. Observe at least one plant and one animal without harming them; confirm both entries appear in the field catalogue with the expected observation facts.
5. Gather a raw resource with the multitool; verify the inventory count and carried-mass limit.
6. Refine or craft an item using an unlocked recipe; confirm exact inputs are consumed and the correct output is granted once.
7. Talk to an NPC. The dialogue must change when the player has relevant evidence or an item, and an unavailable choice must not grant its effect.
8. Accept a quest and complete at least three steps, including one step dependent on an item, evidence record, or world fact.
9. Open a market; buy and sell an item; verify money, player inventory, market stock, quote, and transaction log. Check for negative balances and double transactions.
10. Build one functional base module. Confirm placement, resource cost, power state, and at least one production/utility effect.
11. Change a ship module/loadout, launch back into space, and travel to another system or a controlled test destination.
12. Save, fully terminate the application, launch again, reload, and verify location, inventory, mission step, market deltas, building, ship configuration, discovered species, and story flags.
13. Repeat sensitive operations and verify that one-time rewards cannot be claimed again after reload, app resume, or repeated input.
14. Capture screenshots of key states; store seed, build version, logs, and a test report.

Run this scenario in a deterministic harness on every significant gameplay integration change. Run a UI-driven variant on Android for the release candidate.

#### 2.5 Procedural-generation stress

Run at least 500 reproducible seeds in the first substantial test pass and expand the count as runtime permits. Check for:

- missing star/planet data;
- duplicate stable IDs;
- invalid or overlapping orbit constraints;
- planets with no valid biome or landing solution where one is required;
- unreachably generated mission targets;
- impossible starting loadouts;
- no available resource required by the first recipe;
- ecology definitions inconsistent with climate tags;
- markets that start with negative stock or invalid prices;
- settlements whose essential supply chains have no feasible input;
- empty or disconnected travel graphs where connectivity is expected;
- pathological spawn density or runaway entity counts;
- deterministic mismatch with the same seed and generator version.

Store failed seeds in the report. A fix is not complete until the failing seed is a regression test.

#### 2.6 Visual QA

Capture reference images at representative portrait resolutions and densities, for example a compact phone, a common 1080-pixel-wide phone, a high-density device, a large phone, and a tablet layout. Exact hardware selection should reflect devices the developer can actually test.

Review:

- aspect ratio is preserved and no world stretch occurs;
- HUD does not cover essential play space or active targets;
- controls respect safe areas and are comfortably touchable;
- long localized strings do not clip or overlap;
- buttons have visible disabled/pressed/focused states;
- ship/creature silhouettes remain readable against varied backgrounds;
- visual effects do not hide interactable objects or warning indicators;
- low-quality fallback still communicates water depth, hazards, landing zones, and anomaly boundaries;
- screen shake, glow, scanlines, and distortion can be reduced or disabled;
- black-hole lensing and other effects maintain orientation and UI legibility;
- screen transitions do not show stretched frames or uninitialized textures.

Golden-image comparison may be used, but allow a well-defined tolerance for animated particles, variable timestamps, and intentional noise. For failures, include the current screenshot and reference diff.

#### 2.7 Android/ADB smoke tests

Build an installable debug APK using the real Godot Android export template and configured Android SDK. Test on an emulator and on a physical device if available. Verify:

- clean install and launch;
- portrait orientation and safe-area handling;
- touch movement, multitouch, action selection, UI scroll, and virtual stick reset;
- pause, app backgrounding, return, focus loss, system Back, and process death/relaunch;
- save/load after lifecycle interruption;
- no duplicated movement or action after resume;
- permissions only when actually needed;
- expected graphics fallback on the selected renderer/device;
- logcat contains no crash, resource import failure, shader compilation failure, or repeated error loop;
- memory and frame time remain within the project's budget in a dense scene;
- install/upgrade behavior does not delete a valid save unexpectedly.

Record device/emulator model, Android API level, screen resolution/density, GPU/renderer when available, graphics preset, build identifier, FPS/frame time measured, and the exact tested scenario. ADB automation should use UI element identifiers when available. Raw coordinates are a fallback and must be calibrated to the actual device resolution and density.

### 3. Named regression scenarios

Use stable test IDs and retain them across refactoring:

- `new_game_to_first_landing`
- `observe_creature_without_ecosystem_damage`
- `craft_and_move_inventory_items`
- `trade_market_and_price_changes`
- `build_powered_habitat`
- `ship_module_change_and_save`
- `main_story_choice_and_save_reload`
- `black_hole_route_safety`
- `white_hole_transfer_persists`
- `content_pack_addition_keeps_old_save`
- `low_quality_visual_fallback`
- `app_resume_does_not_duplicate_rewards`
- `failed_craft_rolls_back_inventory`
- `market_stock_is_finite`
- `dialogue_condition_rechecks_before_commit`
- `authored_quest_target_remains_reachable`
- `species_population_recovers_after_habitat_restore`
- `invalid_content_pack_is_rejected_atomically`
- `save_backup_survives_corrupt_primary`
- `touch_input_clears_after_focus_loss`

The first five scenarios should be runnable without MCP through a test API/headless runner. MCP is useful for controlling the real app and collecting visual evidence; it is not needed to test every formula.

### 4. Feature-status rules

Maintain a feature matrix with columns such as `feature_id`, `implementation_status`, `unit_test`, `integration_test`, `desktop_e2e`, `emulator_test`, `physical_device_test`, `known_gaps`, and `evidence_path`.

Allowed statuses:

- `NOT_STARTED`
- `IN_PROGRESS`
- `IMPLEMENTED_NOT_VERIFIED`
- `VERIFIED`
- `BLOCKED`

Never mark a feature `VERIFIED` because it compiles, because a test was planned, or because the main menu opened. A feature is verified only to the scope supported by evidence. For example, `VERIFIED_DESKTOP` and `VERIFIED_ANDROID_EMULATOR` may be recorded as extra scope labels if useful; do not silently conflate them with physical device testing.

### 5. Performance budgets and device tiers

Use Low, Balanced, High, and Ultra profiles. Low reduces particles and lights, disables expensive screen distortion, simplifies reflections, and lowers update rates for offscreen entities. Balanced is the baseline mobile experience. High adds richer normal response, controlled caustics, and more atmosphere. Ultra enables the maximum supported effects but does not require hardware ray tracing.

Aim for 60 FPS on a tested mid-range device during ordinary exploration, with a configurable 30 FPS cap/fallback on weaker hardware or unusually expensive scenes. These are goals to validate, not a guarantee about every phone.

Profile at least: a dense biome, a large base, water plus fog, a cluster of active creatures, a market/settlement simulation update, a black-hole lensing encounter, a landing transition, and save/load with a large inventory. Record frame time, stutter, memory, draw calls/active lights where available, and time spent in expensive scripts. Put explicit limits on particle count and near-field simulation entities.

### 6. Required QA artifacts

Store outputs under `build/reports/` or a deliberate test-artifact directory:

- `headless_import.log`
- `unit_tests.xml` or equivalent runner report
- `integration_tests.json`
- `content_validation.json`
- `generation_stress.json`
- `e2e_vertical_slice.json`
- `android_build.log`
- `device_smoke_report.md`
- `screenshots/` and visual diffs
- `performance_summary.md`
- `known_issues.md`
- environment/version manifest and build identifier

Reports must not include passwords, API tokens, signing keys, personal device data, or other secrets. Do not commit huge temporary traces unless the project deliberately keeps release QA artifacts. Failed tests must include reproduction instructions, seed/context where relevant, log excerpts, and a clear expected-versus-actual description.

---

# Appendix D — Full OpenCode and MCP Reference


### 1. The main principle

There is no single MCP server that magically validates an entire native game. A reliable Godot workflow combines static checks, content validation, unit/integration tests, a deterministic gameplay harness, Android build and device testing, visual inspection, and honest evidence reporting. MCP can let an agent control tools and observe a running app, but it does not replace deterministic tests or human judgment about whether the game feels good to play.

Use as few tool integrations as possible. Every MCP server adds tools and information to the agent's context; a large collection of overlapping servers can make the agent less effective, not more capable. Prefer a compact baseline and add a specialist only when a concrete gap justifies it.

### 2. Baseline toolchain

- **Godot 4.7.2 stable** is the initial version target for this pack. The official release archive identifies 4.7.2 stable as released on 18 August 2026. Verify the version installed on the machine and review official release notes before changing it. Do not upgrade to a beta/RC without an explicit compatibility reason.
- GDScript, with explicit types in save, quest, inventory, economy, content-validation, and generation code where that improves safety and clarity.
- Godot command-line/headless mode for import, parse, project smoke, data tests, and automated test runners.
- Android SDK, Platform Tools (`adb`), a compatible Java/JDK installation, and Godot export templates for the selected engine version.
- Git for checkpoints, reviewable diffs, rollback, and regression isolation. Preserve existing user work and the original HTML prototype.
- GdUnit4 or an equivalent framework for unit/integration tests, after verifying compatibility with the selected Godot release. Current GdUnit4 compatibility tables distinguish framework branches by supported Godot versions; select a compatible release instead of blindly installing latest.
- Android Emulator or a physical test device for platform acceptance. An emulator is useful, but it is not the same evidence as a physical phone.

Official references to verify when working:

- OpenCode MCP servers: https://dev.opencode.ai/v2/docs/mcp-servers/
- OpenCode configuration: https://opencode.ai/v2/docs/config
- Godot stable archive: https://godotengine.org/download/archive/4.7.2-stable/
- Godot Android export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Godot command-line tutorial: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- Godot 2D glow/HDR information: https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html (find the current section on glow in 2D if the documentation structure has changed)
- GdUnit4 project and compatibility: https://github.com/godot-gdunit-labs/gdUnit4
- Android ADB reference: https://developer.android.com/tools/adb
- Android emulator documentation: https://developer.android.com/studio/run/emulator
- adb-mcp repository: https://github.com/iksnerd/adb-mcp
- Context7 MCP: https://mcp.context7.com/mcp

### 3. Required test loop: Godot CLI/headless

Use the command line to import assets, parse scripts, load scenes, validate content, exercise deterministic systems, and run test harnesses without opening the editor UI. Adapt the exact executable name and flags to the installed environment; do not assume `godot`, `godot4`, and a platform-specific binary are interchangeable.

Typical commands may resemble:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --quit
```

These are examples only. The second command proves little by itself and is not a gameplay test. The project must provide dedicated test-runner entry points for unit tests, content lint, generation stress, and end-to-end harness scenarios. Capture exit codes and logs. A test command that silently does nothing is a failed test setup, not a pass.

### 4. GdUnit4 or another Godot test framework

Use the framework for inventory, recipe transactions, price calculations, generation constraints, dialogue and quest conditions, save serialization, migration, ship module compatibility, construction rules, and representative scene behavior. Verify the specific framework release supports the installed Godot version before adding it to the repo. Keep pure logic testable without requiring a live renderer whenever possible.

If framework installation becomes a blocker, start with a small first-party test harness and add a framework later. Do not leave tests unwritten simply because the preferred library is not available.

### 5. Android SDK and ADB

ADB is required for meaningful Android acceptance testing. Use it to inspect connected devices, install a debug APK, launch/stop the app, collect logcat, capture screenshots, check package state, and reproduce lifecycle events.

Verify the exact Java/JDK, Android SDK, platform-tools, target platforms, build tools, and export template requirements against the selected Godot documentation. Store paths in local editor settings/environment, not hardcoded in project files. Keep release-signing keystores and passwords out of Git and logs.

Test installation, launch, fixed portrait behavior, safe areas, touch input, system Back, pause/resume, process death/relaunch, save/load, shader/resource failures, and app crashes. If no emulator/device is available, run the tests that can run headlessly and mark device tests `BLOCKED`. Do not substitute a desktop window for an Android device test.

### 6. adb-mcp — useful but optional

The `adb-mcp` project provides an MCP server for Android emulators and connected devices through ADB. Its repository describes workflows for booting devices, screenshots, UI hierarchy observation, touch/swipe/text input, app lifecycle, logcat, and certain build/test tasks. It is a third-party independent project, not an official Godot or Google component.

Before installation:

1. Read the repository README, current release notes, license, and installation script.
2. Verify the expected OS/architecture, binary checksums, requirements, and whether the server supports the local OpenCode setup.
3. Inspect any shell script before executing it. Prefer a signed/release binary with a verified checksum or a reproducible build path.
4. Ensure Android SDK and ADB are available to the MCP process. A server running in a different environment/container may not be able to see the host's emulator.
5. Limit the tool to the devices and operations needed by the project. Avoid exposing a device or local service to the public network.
6. Test a low-risk workflow first: list devices, capture a screenshot, inspect the foreground app, and read logs before installing or interacting with the game.

Example commands and capabilities can change. Consult the repository at the time of installation rather than treating the following as immutable API promises: https://github.com/iksnerd/adb-mcp

### 7. OpenCode MCP configuration example

Current OpenCode v2 documentation places named servers under `mcp.servers`. The exact schema may change; check `opencode mcp list`, validate the config, and consult the documentation for the installed OpenCode release. Do not combine legacy and v2 shapes in one configuration.

Example `opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "context7": {
        "type": "remote",
        "url": "https://mcp.context7.com/mcp",
        "enabled": true
      },
      "android-adb": {
        "type": "local",
        "command": ["adb-mcp"],
        "enabled": true
      }
    }
  }
}
```

This is an example configuration, not a guarantee that both servers are installed or reachable. `adb-mcp` must exist in the environment's `PATH` or the command must use the correct absolute path. Context7 may require authentication or may not be necessary if the agent uses official documentation directly. Remove a server if the project does not need it.

Useful OpenCode commands include listing MCP connections and checking authentication, but verify exact CLI syntax against the installed version. Keep secrets in environment variables or the tool's auth flow. Never write bearer tokens or API keys directly into a checked-in config file.

### 8. Context7 — optional documentation lookup

Context7 can help an agent retrieve current API documentation for frameworks and libraries. It is optional. Prefer official Godot documentation and version-specific documentation pages for engine APIs. Do not use Context7 as a reason to accept an unverified API call; compile and test the code against the installed version.

### 9. Godot editor bridges and other MCP servers

A Godot editor bridge or scene-inspection MCP can be useful for inspecting a live scene tree, reading node state, or helping the agent understand a visual issue. Treat it as optional and third-party unless it is shipped by the official engine. Verify version compatibility, access scope, license, network binding, and security posture before enabling it. Do not let an unfamiliar bridge perform massive scene changes without reviewing the resulting diff.

Use Playwright only for an actual web surface, such as a content-authoring panel, website, or HTML prototype. Playwright is not evidence that the native Godot APK works correctly, and it is not a replacement for ADB-driven native interaction.

### 10. How the agent must playtest for real

The game should expose a deterministic debug/test harness available only in debug and test builds. It should support starting from a known save/seed, selecting a stable world/entity by ID, performing supported actions, checking state snapshots, and emitting machine-readable outcomes. Release builds must not expose developer cheats or unprotected test commands.

Use a loop of **observe → locate → act → re-observe**. Capture a screenshot, inspect the UI hierarchy where supported, use a stable element ID or accessible label when possible, act, then capture again to confirm the expected result. Do not assume a tap succeeded because a command returned without error.

A full automated playthrough should be able to:

1. create a fresh save;
2. fly and land;
3. observe lifeforms and save catalogue evidence;
4. gather and refine resources;
5. craft an item;
6. accept and progress a mission;
7. trade with a finite-stock market;
8. build and power a base module;
9. change a ship module;
10. trigger and safely navigate a controlled anomaly encounter;
11. save, terminate, restart, and verify every relevant state;
12. capture screenshots and logs at failure points.

Use stable world IDs in deterministic tests. Coordinate taps are appropriate for validating touch layout, but they are brittle for deep logic and should not be the only test mechanism. For every failure, preserve a seed, build version, logs, screenshot, failing step, expected state, and actual state.

### 11. Minimum release gates

1. The project imports and scripts parse without errors in the pinned Godot version.
2. Every JSON/content pack validates; every required referenced ID resolves.
3. Same seed and generator version reproduce the same world; different seeds vary within valid constraints.
4. Economy tests rule out unintended infinite money/item loops and enforce stock/currency bounds.
5. Crafting is atomic and cannot lose materials on failure or duplicate outputs on repeated input.
6. Quest rewards are idempotent and do not duplicate after reload or app resume.
7. Save round-trip works and at least one previous schema migrates safely.
8. The vertical-slice E2E loop passes through save/reload.
9. APK installation and portrait touch smoke test pass on the Android environment actually used.
10. Test reports list the actual device/emulator, API level, resolution, engine version, renderer/preset, build identifier, commands, result, and outstanding gaps.
11. Every unavailable device test is marked `BLOCKED`, not `PASS`.
12. The release build contains no debug cheats, signing secrets, or unapproved network behavior.

### 12. Security and maintenance hygiene

- Give MCP tools only the permissions needed for the task; prefer local-only listeners and stdio integrations when appropriate.
- Do not place tokens, passwords, signing keys, or private device details in Git, prompts, or logs.
- Do not enable telemetry, upload builds, publish releases, or send project files to third-party services without explicit authorization.
- Review Git diffs, changed files, dependency licenses, and generated files after each phase.
- Run the full relevant test suite after integrating parallel-agent work.
- Never claim the physical device was tested if only headless or emulator tests ran.
- Record the environment and commands needed to reproduce a release build. A toolchain that only works on an agent's undocumented machine is not a finished build pipeline.

### 13. Suggested division of labor when using subagents

If the selected OpenCode/model setup supports subagents, delegate only work that can proceed independently. Good examples are: one agent auditing existing architecture and toolchain, one authoring a validated narrative data pack, one reviewing schemas and test coverage, and one investigating renderer/performance constraints. Keep one lead agent responsible for decisions, file ownership, integration, and acceptance gates.

Do not allow several agents to edit the same central state service, save schema, content registry, or quest engine simultaneously. Ask each subagent for a bounded deliverable: a report, a separate branch, or isolated files. The lead agent must review diffs, resolve conflicts, run validation, and rerun relevant tests after integration. Subagent reports are not evidence until the artifacts and tests have been inspected.

### 14. Reproducibility checklist

A useful test report includes:

- repository commit or working-tree identifier;
- Godot/editor version and export-template version;
- host OS and versions of Java/JDK, Android SDK, platform-tools, and emulator;
- device/emulator model, Android API level, screen resolution/density, and renderer when known;
- content-pack and save-schema versions;
- random seed bundle and world/mission IDs;
- exact command lines or automation scenario IDs;
- exit codes and summarized logs;
- screenshots/video files for visual failures;
- observed versus expected behavior;
- known issues and checks blocked by unavailable hardware/tooling.

Do not include secrets, account identifiers, private paths containing personal data, or unnecessary device identifiers. Where a report is shared externally, redact the environment accordingly.

### 15. Current-version caution

The URLs above are starting points, not a license to assume that a tool's API or schema has not changed. Before adding or invoking an integration, read the current official documentation or the project's repository, check the installed version, validate the configuration, and run a minimal smoke test. In particular, distinguish OpenCode's current `mcp.servers` configuration shape from older examples that placed server names directly beneath `mcp`. Do not mix configuration schemas from different OpenCode generations.

---

# Appendix E — Complete Corrected Star Hopper HTML Prototype

The standalone English-language prototype is reproduced in full below. It is historical reference code only; the actual Beyond the Void game must be implemented as a native Godot project in the repository root.

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
<meta name="theme-color" content="#070a13">
<title>Star Hopper — Fixed Prototype</title>
<style>
  :root{color-scheme:dark}
  *{box-sizing:border-box}
  html,body{margin:0;width:100%;height:100%;background:#070a13;font-family:system-ui,sans-serif;overflow:hidden;overscroll-behavior:none}
  .stage{position:relative;width:100vw;height:100vh;height:100dvh;overflow:hidden;background:#070a13;touch-action:none;user-select:none;-webkit-user-select:none}
  #cv{position:absolute;inset:0;width:100%;height:100%;image-rendering:auto;z-index:1;display:block}
  .fx{position:absolute;inset:0;pointer-events:none;z-index:2}
  .scanlines{background:repeating-linear-gradient(0deg,rgba(0,0,0,.28) 0 1px,transparent 1px 3px);animation:flick 4s steps(12) infinite}
  @keyframes flick{0%,100%{opacity:.9}50%{opacity:.75}}
  .vig{background:radial-gradient(ellipse at center,transparent 55%,rgba(0,0,0,.55) 100%)}
  .grain{opacity:.07;animation:gr .5s steps(3) infinite}
  @keyframes gr{0%{background-position:0 0}33%{background-position:24px 40px}66%{background-position:-30px 12px}100%{background-position:0 0}}
  #warpfx{position:absolute;inset:0;background:#000;opacity:0;transition:opacity .45s ease;pointer-events:none;z-index:3}
  .hud{position:absolute;z-index:4;display:flex;gap:8px;align-items:flex-start;flex-wrap:wrap;max-width:calc(100vw - 16px)}
  .hud.tl{top:calc(8px + env(safe-area-inset-top));left:8px;right:8px}
  .hud.tr{top:calc(48px + env(safe-area-inset-top));right:8px;max-width:45vw;flex-direction:column}
  .chip{border:1px solid #2e3340;border-radius:6px;background:rgba(24,28,40,.82);padding:4px 8px;font-size:12px;color:#9aa3b5;backdrop-filter:blur(5px);-webkit-backdrop-filter:blur(5px)}
  .chip b{color:#eef1f7;font-weight:500;font-variant-numeric:tabular-nums}
  #log{display:flex;flex-direction:column;gap:4px;align-items:flex-end}
  #log .chip{font-size:11px;max-width:45vw;overflow-wrap:anywhere}
  .hint{position:absolute;left:50%;transform:translateX(-50%);bottom:calc(4px + env(safe-area-inset-bottom));z-index:4;font-size:12px;color:#8790a5;background:rgba(7,10,19,.72);padding:4px 10px;border-radius:6px;pointer-events:none;white-space:normal;text-align:center;max-width:calc(100vw - 240px)}
  #joy{position:absolute;left:calc(14px + env(safe-area-inset-left));bottom:calc(14px + env(safe-area-inset-bottom));width:clamp(88px,24vw,112px);height:clamp(88px,24vw,112px);border-radius:50%;border:1px solid #3a4358;background:rgba(24,28,40,.42);z-index:5;touch-action:none}
  #stick{position:absolute;left:50%;top:50%;width:40%;height:40%;border-radius:50%;background:rgba(238,241,247,.84);transform:translate(-50%,-50%);pointer-events:none}
  .btns{position:absolute;right:calc(14px + env(safe-area-inset-right));bottom:calc(14px + env(safe-area-inset-bottom));display:flex;flex-direction:column;gap:8px;z-index:5}
  .btns button{border:1px solid #39445c;border-radius:10px;background:rgba(24,28,40,.9);color:#eef1f7;font:600 14px system-ui;padding:13px 14px;min-width:clamp(92px,26vw,112px);min-height:46px;cursor:pointer;backdrop-filter:blur(5px);-webkit-backdrop-filter:blur(5px);transition:transform .12s ease-out;touch-action:manipulation}
  .btns button:active{transform:scale(.96)}
  .btns button:disabled{opacity:.35;cursor:default}
  #scanBtn{border-color:#3d5a8a}
  #toast{position:absolute;top:calc(90px + env(safe-area-inset-top));left:50%;transform:translateX(-50%) translateY(-8px);z-index:6;opacity:0;transition:opacity .25s ease,transform .25s ease;border:1px solid #2e3340;border-radius:8px;background:rgba(24,28,40,.94);color:#eef1f7;font-size:13px;padding:8px 12px;pointer-events:none;max-width:calc(100vw - 32px);text-align:center}
  #toast.show{opacity:1;transform:translateX(-50%) translateY(0)}
  #fxBtn{position:absolute;top:calc(8px + env(safe-area-inset-top));right:8px;z-index:4;cursor:pointer;color:#c0c9dc;font:12px system-ui;min-height:32px}
  @media(max-width:380px){.chip{font-size:11px;padding:3px 6px}.hud.tl{gap:4px}.hint{max-width:calc(100vw - 210px);font-size:10px}.btns button{font-size:12px;padding:10px 9px;min-width:88px}}
  @media(prefers-reduced-motion:reduce){.scanlines,.grain{animation:none}*{scroll-behavior:auto!important;transition:none!important}}
</style>
</head>
<body>
<div class="stage" id="stage">
  <canvas id="cv" aria-label="Star Hopper game field"></canvas>
  <div class="fx scanlines" id="fx1"></div>
  <div class="fx vig" id="fx2"></div>
  <div class="fx grain" id="grain"></div>
  <div id="warpfx"></div>
  <div class="hud tl">
    <span class="chip">System <b id="sysName">—</b></span>
    <span class="chip">✦ <b id="cr">0</b></span>
    <span class="chip">Planets <b id="pf">0/0</b></span>
  </div>
  <div class="hud tr" id="log"></div>
  <button class="chip" id="fxBtn" type="button">CRT: ON</button>
  <div class="hint" id="hint">WASD / arrows — move · Space — scan</div>
  <div id="joy" aria-label="Movement joystick"><div id="stick"></div></div>
  <div class="btns">
    <button id="scanBtn" type="button">Scan</button>
    <button id="warpBtn" type="button">Warp ➤</button>
  </div>
  <div id="toast" role="status" aria-live="polite"></div>
</div>
<script>
'use strict';
const $=id=>document.getElementById(id);
const cv=$('cv'),ctx=cv.getContext('2d',{alpha:false});
// W/H are logical viewport dimensions. They change with the window aspect ratio;
// the canvas backing buffer tracks device pixel ratio, while the world remains undistorted.
let W=480,H=300,viewScale=1,deviceScale=1;
const ACCENT='#4d8dff';
const SYL=['Ka','Zu','En','To','Ri','Ve','Mo','La','Si','Du','No','He','Yur','Fa','Os','Ta','Io','Pa'];
const PHUE=['#7fd8a4','#e8a15c','#8fb4e8','#d98fb8','#c9d66b','#e87f7f'];
const SHUE=['#ffd166','#ff8c5a','#9be7ff','#ffb3d1'];
function resizeCanvas(){
  const rect=$('stage').getBoundingClientRect();
  const width=Math.max(1,rect.width),height=Math.max(1,rect.height);
  viewScale=Math.min(width/480,height/300);
  W=width/viewScale;H=height/viewScale;
  deviceScale=Math.min(window.devicePixelRatio||1,2.5);
  const bw=Math.max(1,Math.round(width*deviceScale)),bh=Math.max(1,Math.round(height*deviceScale));
  if(cv.width!==bw||cv.height!==bh){cv.width=bw;cv.height=bh}
  ctx.setTransform(viewScale*deviceScale,0,0,viewScale*deviceScale,0,0);
  ctx.imageSmoothingEnabled=true;
}
function mulberry(a){return function(){a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
let R=mulberry((Math.random()*1e9)|0);
const pick=arr=>arr[(R()*arr.length)|0];
const nameGen=n=>{let s='';for(let i=0;i<n;i++)s+=pick(SYL);return s};
const WORLD=3200;
let star,planets,rocks,bgStars,sysName,total=0;
const ship={x:0,y:0,vx:0,vy:0,ang:0,heat:0};
let camX=0,camY=0,credits=0,found=0,scanT=0,scanTarget=null,shake=0,warpping=false,tGlob=0,engineSfxCooldown=0;
const keys={},joy={x:0,y:0,on:false};
function genSystem(){
  R=mulberry((Math.random()*1e9)|0);
  sysName=nameGen(2)+'-'+(100+((R()*899)|0));
  star={x:WORLD/2,y:WORLD/2,r:24+R()*12,c:pick(SHUE)};
  planets=[];total=3+((R()*3)|0);
  for(let i=0;i<total;i++)planets.push({orbit:300+i*230+R()*130,ang:R()*6.283,spd:(0.04+R()*0.07)*(R()<0.5?1:-1)/(1+i*0.45),r:11+R()*15,c:pick(PHUE),disc:false,name:nameGen(2),reward:60+((R()*160)|0)});
  rocks=[];for(let i=0;i<70;i++)rocks.push({x:R()*WORLD,y:R()*WORLD,r:3+R()*7,rot:R()*6.283,spr:(R()-0.5)*1.6,pts:Array.from({length:7},()=>0.75+R()*0.5)});
  bgStars=[];for(let i=0;i<260;i++)bgStars.push({x:R()*WORLD,y:R()*WORLD,s:R(),tw:R()*6.28});
  const a=R()*6.283;
  ship.x=star.x+Math.cos(a)*620;ship.y=star.y+Math.sin(a)*620;
  ship.vx=ship.vy=0;ship.heat=0;
}
resizeCanvas();
window.addEventListener('resize',resizeCanvas,{passive:true});
if(window.visualViewport)window.visualViewport.addEventListener('resize',resizeCanvas,{passive:true});
genSystem();
let AC=null;
function beep(f,d,type,v){try{AC=AC||new(window.AudioContext||window.webkitAudioContext)();if(AC.state==='suspended')AC.resume();const o=AC.createOscillator(),g=AC.createGain();o.type=type||'square';o.frequency.value=f;g.gain.setValueAtTime(v||0.035,AC.currentTime);g.gain.exponentialRampToValueAtTime(0.0001,AC.currentTime+(d||0.12));o.connect(g);g.connect(AC.destination);o.start();o.stop(AC.currentTime+(d||0.12))}catch(e){}}
let toastTO=null;
function toast(msg){const t=$('toast');t.textContent=msg;t.classList.add('show');clearTimeout(toastTO);toastTO=setTimeout(()=>t.classList.remove('show'),2200)}
function currentPlanetPosition(p){return{x:star.x+Math.cos(p.ang)*p.orbit,y:star.y+Math.sin(p.ang)*p.orbit}}
function nearestPlanet(){let best=null,bd=1e9;for(const p of planets){if(p.disc)continue;const pos=currentPlanetPosition(p);const d=Math.hypot(pos.x-ship.x,pos.y-ship.y);if(d<p.r+95&&d<bd){bd=d;best={p,px:pos.x,py:pos.y}}}return best}
function logAdd(txt){const l=$('log'),d=document.createElement('span');d.className='chip';d.textContent=txt;l.prepend(d);while(l.children.length>3)l.lastChild.remove()}
function doScan(){if(scanTarget||warpping)return;const n=nearestPlanet();if(!n){toast('No target within scanner range');return}scanTarget=n.p;scanT=0;beep(520,0.1)}
function doWarp(){if(warpping)return;warpping=true;beep(180,0.5,'sawtooth',0.05);$('warpfx').style.opacity=1;setTimeout(()=>{genSystem();found=0;scanTarget=null;scanT=0;$('log').innerHTML='';updateHUD();toast('System '+sysName);$('warpfx').style.opacity=0;warpping=false;beep(660,0.15)},520)}
$('scanBtn').addEventListener('click',doScan);$('warpBtn').addEventListener('click',doWarp);
$('fxBtn').addEventListener('click',()=>{const on=$('fx1').style.display!=='none';['fx1','fx2','grain'].forEach(i=>$(i).style.display=on?'none':'block');$('fxBtn').textContent=on?'CRT: OFF':'CRT: ON'});
if('ontouchstart'in window)$('hint').textContent='Joystick — move · Approach a planet to scan it';
const joyEl=$('joy'),stick=$('stick');let joyId=null;
function jmove(e){const r=joyEl.getBoundingClientRect();let dx=e.clientX-(r.left+r.width/2),dy=e.clientY-(r.top+r.height/2);const max=Math.max(1,r.width/2-14),l=Math.hypot(dx,dy);if(l>max){dx*=max/l;dy*=max/l}stick.style.transform=`translate(calc(-50% + ${dx}px),calc(-50% + ${dy}px))`;joy.x=dx/max;joy.y=dy/max}
joyEl.addEventListener('pointerdown',e=>{e.preventDefault();joyId=e.pointerId;joy.on=true;joyEl.setPointerCapture(e.pointerId);jmove(e)});
joyEl.addEventListener('pointermove',e=>{if(e.pointerId===joyId)jmove(e)});
const jend=e=>{if(e.pointerId===joyId){joyId=null;joy.on=false;joy.x=joy.y=0;stick.style.transform='translate(-50%,-50%)'}};
joyEl.addEventListener('pointerup',jend);joyEl.addEventListener('pointercancel',jend);joyEl.addEventListener('lostpointercapture',jend);
addEventListener('keydown',e=>{const k=e.key.toLowerCase();keys[k]=true;if(e.key===' '){e.preventDefault();doScan()}if(['arrowup','arrowdown','arrowleft','arrowright',' '].includes(k))e.preventDefault()});
addEventListener('keyup',e=>{keys[e.key.toLowerCase()]=false});
function clearInput(){for(const k of Object.keys(keys))keys[k]=false;joy.x=joy.y=0;joy.on=false;joyId=null;stick.style.transform='translate(-50%,-50%)'}
addEventListener('blur',clearInput);document.addEventListener('visibilitychange',()=>{if(document.hidden)clearInput()});
document.addEventListener('pointerdown',()=>{try{AC=AC||new(window.AudioContext||window.webkitAudioContext)();AC.resume()}catch(e){}},{once:true});
(function grain(){const g=document.createElement('canvas');g.width=g.height=128;const c=g.getContext('2d'),id=c.createImageData(128,128);for(let i=0;i<id.data.length;i+=4){const v=(Math.random()*255)|0;id.data[i]=id.data[i+1]=id.data[i+2]=v;id.data[i+3]=255}c.putImageData(id,0,0);$('grain').style.backgroundImage='url('+g.toDataURL()+')'})();
function input(){let x=0,y=0;if(keys['arrowup']||keys['w'])y-=1;if(keys['arrowdown']||keys['s'])y+=1;if(keys['arrowleft']||keys['a'])x-=1;if(keys['arrowright']||keys['d'])x+=1;if(joy.on){x=joy.x;y=joy.y}const l=Math.hypot(x,y);return l>0.12?{x:x/l,y:y/l,m:Math.min(1,l)}:{x:0,y:0,m:0}}
function update(dt){
  tGlob+=dt;engineSfxCooldown=Math.max(0,engineSfxCooldown-dt);
  const inp=input();
  if(inp.m>0&&!warpping){ship.vx+=inp.x*250*dt*inp.m;ship.vy+=inp.y*250*dt*inp.m;const ta=Math.atan2(ship.vy,ship.vx);let da=ta-ship.ang;while(da>Math.PI)da-=6.283;while(da<-Math.PI)da+=6.283;ship.ang+=da*Math.min(1,dt*9);if(engineSfxCooldown<=0){beep(70+Math.random()*30,0.05,'triangle',0.012);engineSfxCooldown=0.09}}
  const dr=Math.exp(-1.5*dt);ship.vx*=dr;ship.vy*=dr;
  const sp=Math.hypot(ship.vx,ship.vy),mx=220;if(sp>mx){ship.vx*=mx/sp;ship.vy*=mx/sp}
  ship.x=Math.max(20,Math.min(WORLD-20,ship.x+ship.vx*dt));ship.y=Math.max(20,Math.min(WORLD-20,ship.y+ship.vy*dt));
  for(const p of planets)p.ang+=p.spd*dt;
  for(const r of rocks){r.rot+=r.spr*dt;const dx=ship.x-r.x,dy=ship.y-r.y,d=Math.hypot(dx,dy);if(d<r.r+9){const safeD=Math.max(d,0.0001),nx=d>0?dx/safeD:1,ny=d>0?dy/safeD:0;ship.x=r.x+nx*(r.r+9.5);ship.y=r.y+ny*(r.r+9.5);const dot=ship.vx*nx+ship.vy*ny;if(dot<0){ship.vx-=1.6*dot*nx;ship.vy-=1.6*dot*ny;shake=5;beep(140,0.08,'sawtooth',0.04)}}}
  const ds=Math.hypot(star.x-ship.x,star.y-ship.y);
  if(ds<star.r+85){ship.heat=Math.min(1,ship.heat+dt*1.1);if(ship.heat>=1){const safeD=Math.max(ds,0.0001),nx=ds>0?(ship.x-star.x)/safeD:1,ny=ds>0?(ship.y-star.y)/safeD:0;ship.vx=nx*320;ship.vy=ny*320;ship.heat=0.45;shake=9;toast('⚠ Engine overheating!');beep(220,0.3,'sawtooth',0.06)}}else ship.heat=Math.max(0,ship.heat-dt*0.7);
  if(scanTarget){const p=scanTarget,pos=currentPlanetPosition(p),d=Math.hypot(pos.x-ship.x,pos.y-ship.y);if(p.disc||d>p.r+150){scanTarget=null;scanT=0}else{scanT+=dt;if(scanT>=1.3){p.disc=true;found++;credits+=p.reward;scanTarget=null;scanT=0;toast('Planet discovered: '+p.name+' · +'+p.reward+'✦');logAdd('✓ '+p.name+' · +'+p.reward);beep(740,0.12);setTimeout(()=>beep(990,0.15),120);updateHUD()}}}
  camX=Math.max(0,Math.min(WORLD-W,ship.x-W/2));camY=Math.max(0,Math.min(WORLD-H,ship.y-H/2));shake=Math.max(0,shake-dt*14);updateHUD();
}
function updateHUD(){$('sysName').textContent=sysName;$('cr').textContent=credits;$('pf').textContent=found+'/'+total;$('scanBtn').disabled=!(scanTarget||nearestPlanet())}
function draw(){
  ctx.fillStyle='#070a13';ctx.fillRect(0,0,W,H);const ox=(Math.random()-0.5)*shake,oy=(Math.random()-0.5)*shake;ctx.save();ctx.translate(ox,oy);
  for(const s of bgStars){let sx=(s.x-camX*0.55)%WORLD;if(sx<0)sx+=WORLD;let sy=(s.y-camY*0.55)%WORLD;if(sy<0)sy+=WORLD;if(sx<W&&sy<H){const a=0.3+0.7*Math.abs(Math.sin(tGlob*1.5+s.tw));ctx.fillStyle=`rgba(255,255,255,${(a*(0.3+s.s*0.7)).toFixed(2)})`;ctx.fillRect(sx|0,sy|0,s.s>0.8?2:2,s.s>0.8?2:1)}}
  ctx.strokeStyle='rgba(255,255,255,0.07)';ctx.setLineDash([2,4]);ctx.lineWidth=1;for(const p of planets){ctx.beginPath();ctx.arc(star.x-camX,star.y-camY,p.orbit,0,6.283);ctx.stroke()}ctx.setLineDash([]);
  const sx=star.x-camX,sy=star.y-camY,pul=Math.sin(tGlob*2)*1.5;
  if(sx>-80&&sx<W+80&&sy>-80&&sy<H+80){const g=ctx.createRadialGradient(sx,sy,0,sx,sy,star.r*4);g.addColorStop(0,star.c+'55');g.addColorStop(1,'transparent');ctx.fillStyle=g;ctx.fillRect(sx-star.r*4,sy-star.r*4,star.r*8,star.r*8);ctx.fillStyle=star.c;ctx.beginPath();ctx.arc(sx,sy,star.r+pul,0,6.283);ctx.fill();ctx.fillStyle='#fff';ctx.beginPath();ctx.arc(sx,sy,star.r*0.45+pul*0.3,0,6.283);ctx.fill()}
  for(const p of planets){const pos=currentPlanetPosition(p),px=pos.x-camX,py=pos.y-camY;if(px<-40||px>W+40||py<-40||py>H+40)continue;const la=Math.atan2(py-sy,px-sx);ctx.save();ctx.beginPath();ctx.arc(px,py,p.r,0,6.283);ctx.clip();ctx.fillStyle=p.c;ctx.fillRect(px-p.r,py-p.r,p.r*2,p.r*2);ctx.fillStyle='rgba(0,0,20,0.45)';ctx.beginPath();ctx.arc(px-Math.cos(la)*p.r*0.6,py-Math.sin(la)*p.r*0.6,p.r,0,6.283);ctx.fill();if(((px|0)+(py|0))%9<4){ctx.fillStyle='rgba(255,255,255,0.08)';ctx.fillRect(px-p.r,py-1,p.r*2,1)}ctx.restore();if(p.disc){ctx.strokeStyle=ACCENT;ctx.lineWidth=1;ctx.beginPath();ctx.arc(px,py,p.r+3,0,6.283);ctx.stroke()}else if(Math.hypot(pos.x-ship.x,pos.y-ship.y)<170){ctx.fillStyle='rgba(255,255,255,0.6)';ctx.font='9px system-ui';ctx.textAlign='center';ctx.fillText('?',px,py+3)}if(scanTarget===p){ctx.strokeStyle=ACCENT;ctx.lineWidth=2;ctx.beginPath();ctx.arc(px,py,p.r+6,-1.57,-1.57+6.283*(scanT/1.3));ctx.stroke();ctx.setLineDash([3,3]);ctx.strokeStyle='rgba(255,255,255,0.4)';ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(ship.x-camX,ship.y-camY);ctx.lineTo(px,py);ctx.stroke();ctx.setLineDash([])}}
  ctx.fillStyle='#3a3f4d';for(const r of rocks){const rx=r.x-camX,ry=r.y-camY;if(rx<-20||rx>W+20||ry<-20||ry>H+20)continue;ctx.save();ctx.translate(rx,ry);ctx.rotate(r.rot);ctx.beginPath();for(let i=0;i<7;i++){const a=i/7*6.283,rr=r.r*r.pts[i];i?ctx.lineTo(Math.cos(a)*rr,Math.sin(a)*rr):ctx.moveTo(Math.cos(a)*rr,Math.sin(a)*rr)}ctx.closePath();ctx.fill();ctx.strokeStyle='#565d70';ctx.lineWidth=1;ctx.stroke();ctx.restore()}
  ctx.save();ctx.translate(ship.x-camX,ship.y-camY);ctx.rotate(ship.ang);const inp=input();if(inp.m>0){ctx.fillStyle=`rgba(255,${(140+Math.random()*80)|0},60,0.9)`;ctx.beginPath();ctx.moveTo(-6,-3);ctx.lineTo(-6-Math.random()*8-6,0);ctx.lineTo(-6,3);ctx.fill()}ctx.fillStyle='#e8e8f0';ctx.beginPath();ctx.moveTo(9,0);ctx.lineTo(-6,-5);ctx.lineTo(-3,0);ctx.lineTo(-6,5);ctx.closePath();ctx.fill();ctx.fillStyle=ACCENT;ctx.fillRect(-1,-1.5,4,3);ctx.restore();
  if(ship.heat>0.05){ctx.fillStyle=`rgba(255,60,30,${(ship.heat*0.22).toFixed(2)})`;ctx.fillRect(0,0,W,H)}ctx.restore();
}
let last=performance.now();function loop(t){const dt=Math.min(0.05,Math.max(0,(t-last)/1000));last=t;update(dt);draw();requestAnimationFrame(loop)}
updateHUD();requestAnimationFrame(loop);
</script>
</body>
</html>
```


## Final consistency rule

The embedded companion documents are full reference copies to make this master file self-contained. The individual companion files remain the convenient canonical documents for editing. If a requirement changes, update the canonical companion document and the corresponding main-prompt section, then regenerate or reconcile this embedded copy. Do not allow the duplicated copies to drift.
