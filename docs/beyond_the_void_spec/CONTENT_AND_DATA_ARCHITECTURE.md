# BEYOND THE VOID — Content and Game-System Architecture

## 1. Platform and design constraints

- Initial engine target: **Godot 4.7.2 stable**, using GDScript. Before installing or changing versions, inspect the project and verify compatibility against the official release notes. Do not select a beta or release candidate merely because it is newer.
- Primary platform: native Android. Design from the start for portrait-oriented phones, one-handed and two-handed touch input, variable DPI, safe areas, memory pressure, and lifecycle interruptions. Tablet, Windows, Linux, and macOS are secondary targets. Web export is optional and must not distort the native architecture.
- The core single-player experience must work offline. No mandatory server, account, advertising, analytics, or monetization system is required.
- The game is genuinely 2D, preferably top-down for navigation and exploration. Perceived depth comes from layered composition, normal maps, shaders, lighting, distortion, animation, and carefully art-directed materials rather than a hidden requirement to build a full 3D game.
- Design for capability tiers. No single graphics effect may be required for gameplay readability. The game must remain playable when advanced post-processing is disabled.

## 2. Non-negotiable data-driven rules

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

## 3. Recommended repository structure

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

## 4. Content-pack manifests and story updates

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

## 5. Deterministic procedural generation

Generation must be reproducible from stable seeds. Use independent seed streams for galaxy, region, star system, planet, biome, ecology, settlement, and local decoration. A change to a cosmetic rock distribution must not reroll market stock or move a mission NPC on a different planet.

Store seeds, generator version, and player-created deltas, not a full serialized copy of every procedural decoration. Use canonical identifiers for generated locations and entities so quest state can refer to them across save/load.

### World hierarchy

1. **Galaxy:** thematic regions, reachable-system graph, faction zones, major anomalies, trade corridors, uncharted sectors, authored landmarks, and long-distance navigation constraints.
2. **Region:** star systems, transit connections, local conflicts, supply crises, cultural migration, route security, and regional effects.
3. **Star system:** star type, orbit parameters, planets, debris, stations, markets, anomaly fields, traffic, navigation beacons, and local events.
4. **Planet:** atmosphere, temperature, gravity, pressure, liquid types, day length, seasons, weather, climate regions, biomes, flora/fauna communities, resources, settlements, and landing restrictions.
5. **Biome and chunk:** points of interest, structural footprints, vegetation, hazards, creature territories, water features, caves, resource nodes, ambient audio, and local travel routes.
6. **Entity:** stable world UID, generator provenance, transform/state, ecological or economic relationships, quest associations, and save delta if modified by the player.

### Generation invariants

- The starting region always includes a safe landing location, an initial resource loop, an accessible early trade/service node, and a route to the first authored objective.
- The generator must not use an unbounded search loop to find a valid landing zone or quest location. Use bounded attempts and a deterministic fallback template.
- Authored locations and mission-critical objects receive procedural placement constraints; random generation must never contradict story continuity.
- A mission objective must be reachable or have a documented fail-forward alternative. Do not put a required object behind a hazard that the player cannot yet survive.
- Log the seed, generator version, system ID, planet ID, and constraint failures. Every generation bug must be reproducible from a seed bundle.
- Simulate nearby entities in detail, the current region at population/economy level, and distant systems through event-driven aggregate updates. Do not run high-frequency physics for a galaxy the player cannot see.
- Generate a real graph of reachable systems and route constraints, not just a decorative map with randomly positioned dots.

## 6. Visual architecture: high-end 2D without false RTX promises

Do not promise hardware ray tracing on arbitrary Android devices. Aim for a convincing ray-tracing-inspired visual style through carefully art-directed 2D techniques: normal-map lighting, local lights, occluders, reflection strips, screen-space distortion, animated caustics, layered haze, particles, bloom, and responsive material shaders. High-end settings may combine several effects, but every important visual state must have a lower-cost fallback.

### Materials and visual treatment

- **Deep space:** layered nebula silhouettes with distinct depth planes, sparse dust, restrained color fields, luminous stellar coronas, small lensing cues, and occasional thin light rays. Avoid filling every pixel with fog and bloom; negative space is part of the composition.
- **Planets:** readable terminator, cloud band, atmosphere rim, biome palette, local reflected light, and a visible distinction between illuminated and unlit terrain.
- **Water:** animated normals, shallow/deep color absorption, reflection bands, edge foam, underwater haze, surface distortion, moving caustic patterns, and transparent transitions between shore and depth. Caustics should be tiled/animated rather than recalculated as full physical light transport.
- **Glass and crystal:** directional reflection streaks, subtle internal haze, condensation or scratches where appropriate, colored edge response, limited background refraction, and material-specific roughness. Avoid a universal fake-chrome shader on every surface.
- **Metal:** broad soft reflections, directional highlights, normal response, worn corners, and local color bounce. Different alloys must vary in roughness and temperature response.
- **Organic matter:** species-specific roughness, translucency, subsurface-like color effects, bioluminescence, microanimation, and environment-colored reflections. These are stylized shader cues, not claims of full physical subsurface scattering in 2D.
- **Black holes:** asymmetric accretion disk, stylized gravitational lensing that distorts background layers, shifted star positions, particulate flow, radiation zones, and a readable risk boundary.
- **White-hole events:** a distinct discharge of matter and information, unstable geometry, and a visual signature that communicates a transition without implying scientifically established mechanics.

Build one early visual showcase containing water, glass/crystal, light shafts, fog, and reflective metal. Profile it before building many similar materials. Each expensive effect needs a toggle, a quality tier, and a fallback. Prefer atlases, pooled particles, limited active lights, cached normal-map data, and lower update rates for distant simulation. Measure the actual render cost rather than assuming a high logical resolution is free.

### Quality tiers

- **Low:** reduced particle count, simpler lighting, no expensive screen distortion, reduced reflection passes, smaller offscreen buffers, simplified water caustics.
- **Balanced:** target mobile baseline with normal lighting, restrained glow, low-cost reflections, and readable atmosphere.
- **High:** additional local lights, richer normal response, more particles, higher-quality water and glass, and more subtle screen distortion.
- **Ultra:** maximum supported stylized effects without requiring hardware ray tracing. It must still respect device limits and have a graceful fallback.

Allow separate controls for glow, screen shake, chromatic effects, scanlines, camera motion, contrast, and particles. Visual accessibility and device performance both matter.

## 7. Android UX and input architecture

Portrait mode is the default design target. Do not force a landscape layout into a narrow screen by merely shrinking all buttons. Account for cutouts, edge-to-edge system UI, safe areas, dynamic system bars, variable density, small phones, large phones, and tablets.

The central viewport should occupy roughly 55–70% of available height during exploration. Keep the top strip for a compact status/combat/navigation objective and the lower strip for contextual actions and a small inventory quick-access area. Do not permanently cover large amounts of world space with panels.

Support configurable touch zones, stick size and sensitivity, left-handed/right-handed layouts, one-handed and two-handed use, haptic feedback toggle, text scaling, subtitles, contrast options, reduced motion, and a separate control scheme for keyboard/controller. Important actions must never depend on tiny precision taps. Do not put a destructive or expensive interaction under the same coordinate as an ordinary movement control.

Use a central `InputRouter` and explicit interaction state. Clear held inputs on focus loss, scene transitions, pause/resume, or device interruption. Avoid duplicate input when touch gestures produce both a UI signal and world interaction. Provide a visible control hint for the current context, not a static tutorial banner covering the screen forever.

Core screens include main menu, settings, space HUD, system map, landing sequence, planet surface, inventory, storage, crafting, trading, multitool wheel, ship loadout, base placement, dialogue, quest journal, field catalogue, save/load, and content-update overview. Every screen must support loading, empty, error, success, and disabled states as appropriate. No cosmetic button may imply a feature that does not work.

## 8. Lifeforms and ecological simulation

Every lifeform record includes stable ID, morphology, body plan, size class, animation set, movement mode, surface material, temperature/humidity/pressure/gravity tolerance, food tags, activity cycle, senses, communication, behavior profile, ecological relationships, migration, reproduction conditions, environmental response, player response, observation requirements, and safe sampling rules.

Include ecological roles such as pollinator, scavenger, decomposer, symbiont, competitor, migratory swarm, territorial organism, predator/prey abstraction, colony intelligence, filter feeder, parasite, seed disperser, reef builder, and living weather indicator. Behavior states may include `idle`, `wander`, `forage`, `flee`, `investigate`, `group_follow`, `defend_nest`, `rest`, `seek_shelter`, `migrate`, `courtship`, and `react_to_player`.

Use levels of simulation detail. Nearby organisms have visible behavior and local interactions; organisms elsewhere in the current biome use population-level updates; distant planets use aggregated ecology metrics and event-driven changes. Do not simulate every individual in every generated system at full frame rate.

The first vertical slice must include at least 12 flora and 12 fauna definitions, with real ecological distinctions. The first larger playable content release should reach at least 30 genuinely different flora and 30 fauna definitions. Cosmetic recolors do not count as distinct species. Differences should involve body plan, habitat, behavior, ecology, sound, or interaction.

Do not make killing rare organisms the only way to obtain vital materials. Provide alternatives such as naturally shed material, cultivation, trade, salvage, or habitat restoration. Record population harm and make it matter to the local ecosystem. Some organisms should be dangerous, but not all encounters should be combat encounters.

The field catalogue reveals information gradually. It should record observations, evidence confidence, time and biome, behavior, diet, ecological links, vocalizations, and how a conclusion was reached. The player may form incorrect early hypotheses, but later evidence must allow correction. Never reveal a complete encyclopedia before discovery.

## 9. Intelligent cultures, settlements, factions, and NPCs

Cultures need history, material foundations, taboos, communication style, social organization, environmental relationship, internal disagreement, humor, and changing norms. Do not reduce a culture to “warriors,” “merchants,” or “wise elders.” Example cultural directions include:

- **Tidekeepers:** descendants of coastal settlements whose identity is built around maintaining water infrastructure, obligations, and intergenerational memory. Their commitment to stability can suppress individual choice.
- **Lantern Union:** transport cooperatives and courier families whose power comes from navigation knowledge, route infrastructure, and reputation. Their neutrality is not always morally neutral.
- **Ash Archivists:** caretakers of records from dead settlements who disagree about whether a stored voice should be allowed to change as new witnesses contribute evidence.
- **Seven Orbits Compact:** a loose network of autonomous stations with different legal practices, trade rules, and arbitration systems.
- **The Unborn:** a community of synthetic and post-biological persons that emerged from rescue systems and voluntary memory migrations. They are not simply an evil AI faction.

Each NPC should have stable ID, cultural context, role, schedule/routine, needs, current task, notable memories, relationships, available dialogue, knowledge boundaries, secrets, and a controlled set of world-state reactions. Do not model every thought of every NPC; persist significant facts and aggregate repetitive detail.

Dialogue branches should depend on world facts, not just the last selected line: reputation, evidence, inventory, current mission state, time, player discoveries, cultural context, companion presence, environmental event, and prior promises. Put these conditions in data and evaluate them through registered condition types.

## 10. Trade and the living economy

Trading is a core activity, not a menu that generates infinite stock. Every market has inventory, storage capacity, production, consumption, demand, route access, delivery delays, taxes/fees, security state, and possibly seasonal shifts. Every trade must change stock and player resources atomically.

### Economic entities

- Good definition: category, rarity, mass/volume, base value, storage condition, legality, quality/hazard tags, sources, processing methods, production chain, shelf life where applicable, and localized name/description.
- Market/settlement: stock, target stock, storage capacity, supply, demand, local production, consumption, population, infrastructure, seasonality, taxes, risk, and faction modifiers.
- Trade route: travel time, threat chance, tolls, signal reliability, cargo limit, political relations, route state, and open/closed transition.
- Merchant profile: trust, licenses, debt, credit, unique stock policy, reputation effects, and dialogue states.
- Events: shortages, harvest surpluses, repair demand after storms, quarantine, route closure, local celebration, faction blockade, refugee arrival, and infrastructure failure.

### Price model

Purchase/sale prices may depend on base value, stock ratio, demand, supply, local production, consumption, distance/logistics cost, reputation, taxes, quality, legality, and temporary events. Clamp prices to verified minimum and maximum factors, use integer-safe currency accounting, and record the inputs that determine a displayed quote. Do not update the economy every rendered frame; advance it on a simulation schedule, on market opening when due, and after relevant events.

Explain enough to let the player make an informed choice: why a good is expensive, where it is scarce, when stock last changed, and which local industry needs it. Hidden simulation detail is acceptable; incomprehensible price randomness is not.

### Example economic loops

- Coastal settlements produce saltglass and organic filters but depend on imported alloys.
- Orbital repair networks consume cable, heat sinks, composites, and engine components.
- Biodome colonies require clean water, spores, nutrient medium, and lighting generators.
- Research stations pay for unusual samples, ecosystem surveys, and verified field data.
- Caravans require safe routes, repair services, fuel, and replacement cargo modules.
- Delivering a large shipment may saturate a market and lower the sale price. Restoring a production facility can change both prices and settlement life.

Automate market exploit tests. Profitable routes are allowed, but depend on cargo space, time, route risk, changing demand, market saturation, and competing deliveries. Do not create a guaranteed unlimited buy-low/sell-high loop between two stores.

## 11. Items, inventory, crafting, and research

Use many items, but every item must have a source, application, meaningful world connection, and role in crafting, ecology, trade, mission logic, construction, or collection. Do not create a thousand recolored resources only to inflate a count.

Item categories include raw resources, refined materials, alloys, ceramics, glass-like materials, conductors, electronics, energy cells, consumables, medical/biological supplies, food cultures, biological samples, artifacts, tools, ship modules, building components, decorations, maps/data, access keys, trade goods, quest objects, and collectibles.

Every item record contains stable ID, localization keys, description, category, mass/volume, stack limit, rarity, base value, tags, icon, valid uses, recipe references, source references, market profile, unique properties, and schema version. Game code must not test a display string like `"saltglass_shard"` in dozens of systems. Resolve the typed record through a central registry.

Target at least 80 meaningful items and 40 recipes in the first large playable content pack, plus at least 12 artifacts/blueprints. These targets are not permission to invent meaningless filler. Each must participate in a working loop.

### Inventory behavior

- Provide a quick-access view with clear counts and contextual actions.
- Support category/tag filters, search, sort, details, comparisons, lock/favorite, stack splitting/merging, weight display, and destination selection.
- Use drag-and-drop on desktop and accessible tap-select/tap-destination interactions on phones.
- Track personal inventory, ship cargo, base storage, and container storage separately, each with clear limits.
- Validate stack rules, unique items, ownership, and count boundaries. Negative quantities and duplication through double-tap, re-entrant signals, or resume events must be impossible.
- Show a clear failure reason when capacity or item constraints prevent an operation.

### Recipes and research

A recipe record includes input items/quantities, output items/quantities, station, duration, energy, technology requirements, mission/unlock/reputation gates, optional byproducts, quality/risk information, UI metadata, and schema version. Gathering, refining, and crafting are distinct processes. A raw material may feed several useful production paths and thus affect the economy.

Stations may include handheld field assembly, portable repair bench, refinery, chemical/biological lab, base workbench, shipyard, and research table. Validate recipe graphs for missing inputs, impossible unlock chains, zero/negative quantities, and free cycles that multiply resources. Crafting is atomic: validate and reserve ingredients before consumption; commit once; grant outputs once. On failure, ingredients are not lost.

Technology research should not consist only of an endless grind bar. Combine field data, material samples, NPC help, ruins access, and story discoveries. Explain why a technology has become available and which prerequisites remain.

## 12. Multitools, field tools, and defensive equipment

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

## 13. Ships and propulsion technologies

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

### Twelve propulsion/power/special-module concepts

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

## 14. Bases, settlements, and construction

Provide a useful mobile placement system: transparent ghost preview, grid/surface snapping, rotation, collision and placement feedback, cancel/confirm, cost preview, biome/terrain restrictions, power/support requirements, and a readable reason when placement is rejected. Support planetary surfaces and selected orbital/special locations.

Building modules may include habitation, storage, fabricator, refinery, power generator, battery, greenhouse, water/atmosphere processor, animal observation bay, lab, communication mast, landing pad, market kiosk, protective shell, habitat restoration unit, medical pod, transport link, decorative lighting, furniture, cargo lift, and drone station.

Each building has a stable instance ID, definition ID, health, power state, inputs/outputs, maintenance needs, ownership, location, and saved modification data. A simple power graph is acceptable if it is legible to the player; a complete electrical engineering simulator is not required. Modules must enter a clear degraded state when power is unavailable rather than silently continuing to produce resources.

Settlements have population, needs, supplies, production jobs, events, cultural norms, ecological state, and relations. Player actions can restore local industry, establish a trade route, create a bioshelter, resolve disputes, or open a research post. Construction can change the local landscape and ecology, so provide warnings, reversible placement where possible, and alternative locations.

## 15. Mission taxonomy and data-driven quest architecture

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

### Quest-system invariants

- State changes are transactional and saved at safe transition points.
- A mission's current stage is represented explicitly, not inferred from which scene happens to be open.
- Completing the same objective twice is safe and does not duplicate rewards.
- Optional content can be unavailable without breaking the main campaign.
- UI displays the current objective and explains blockers, but does not fabricate success.
- Journal entries preserve meaningful history after a mission has been completed, abandoned, or migrated.

## 16. Dialogue architecture and localization

Every dialogue has stable ID, locale-independent node IDs, entry node, conditions, choices, effects, speaker metadata, contextual tags, and fallback behavior. All visible strings use localization keys. Each choice is evaluated against current world state at the time it is shown and again when committed, preventing stale UI from granting invalid effects.

Do not implement conditional dialogue through long chains of `if/else` in NPC scripts. The runtime registers conditions and effects, and data references them. Every node must be reachable or explicitly declared as a debug-only orphan; every non-terminal path must lead somewhere valid; loops must be deliberate and have a visible exit. Validate variables, pluralization, interpolation, and missing localization entries.

Localization priority is English for this source content pack. If another locale is shipped, keep display text separate from IDs and validate fallback behavior. Do not translate or mutate stable IDs when adding a locale. Narrative voices must remain authored and reviewed, not generated ad hoc at runtime.

## 17. Save data and content compatibility

A save contains schema version, game version, generator version, content-pack versions, world seeds, player location/state, ship hull and modules, inventory, storage, active/completed mission states, story facts, character relationships, local market deltas, player-built structures, discoveries, unlocked recipes, settings, and a migration history.

Do not serialize every static definition or procedural decorative object. Regenerate deterministic world content from the same seed and persist only player changes and dynamic state that cannot be reconstructed safely. Use stable UIDs for player-created objects and mission-relevant entities.

Save writes must be atomic: write a temporary file, validate it, then replace the active slot; maintain a backup or rotating slot. Corrupt data must not silently overwrite the only good save. Use multiple slots if feasible. Migrations should be explicit and version-by-version; log migration failures, preserve a recoverable copy, and provide a safe user-facing message.

Test round trips, interrupted writes, corrupt JSON/binary files, missing optional content packs, renamed/retired IDs, unknown future fields, old mission states, and save migration after a content update. The game must not duplicate rewards on restore.

## 18. Audio, performance, and diagnostics

Audio should build loneliness and scale without continuous noise. Use sparse ship ambience, low-volume mechanical details, species-specific calls, distant signals, location-based reverberation where practical, and silence after emotionally heavy scenes. Music should support exploration rather than constantly announcing danger. Provide master/music/ambience/effects/voice controls and subtitle options. Use audio pooling or reuse nodes where frequent events would otherwise allocate many objects.

Define performance budgets for active entities, lights, shader passes, particles, audio voices, loaded textures, save time, and content validation. Profile a dense biome, large base, water/fog scene, crowd of creatures, black-hole lensing effect, and landing transition. Set quality defaults based on actual device measurements. Do not make an arbitrary promise that every Android phone will run at the same FPS.

Diagnostics should log stable IDs, seed context, mission stage, content-pack version, and a readable error without dumping sensitive device data. Debug cheats and test-only commands must be excluded or guarded from release builds.

## 19. Acceptance criteria

- The project imports in the pinned Godot version without parser/import errors.
- A complete vertical loop works: menu → ship flight → landing → surface exploration → NPC/creature interaction → crafting → trade → base or ship improvement → mission step → save/restart/load.
- The systems actually interact. For example, ecology affects resources, resources affect production, production affects markets, markets affect quests, and quests affect character/world state.
- Same seed plus same generator version produces a reproducible world; content IDs and references validate.
- All visible text is externalized; content can be extended without hardcoding story into runtime code.
- The Android APK builds, installs, launches in portrait orientation, responds to touch, and resumes without duplicating rewards when SDK/emulator access is available.
- Test reports identify the actual device/emulator, API level, resolution, renderer, quality preset, build version, commands, results, and known limitations.
- Any unverified behavior remains marked unverified. The absence of a device is a test limitation, not a pass.
