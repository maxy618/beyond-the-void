# BEYOND THE VOID — Quality Assurance and Automated Playtesting Plan

## 1. Principle: test behavior, not merely startup

A project that imports successfully is not a tested game. A build that opens to a menu is not evidence that inventory, markets, missions, ecology, saving, or touch controls work. Every feature must have a testable contract, a repeatable setup, an expected result, and logs that make failures diagnosable.

Use layered tests: static source checks, content validation, unit tests, integration tests, deterministic simulation tests, end-to-end gameplay scenarios, visual review, Android emulator tests, and physical-device smoke tests where a device is available. Keep the test path deterministic so a failed test does not require an agent to manually rediscover a random planet every time.

Never claim physical-device coverage if only a desktop build, headless run, or emulator was tested. Record `BLOCKED` when required hardware/tooling is unavailable. Report what actually ran, not what was intended to run.

## 2. Test layers

### 2.1 Static analysis and content validation

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

### 2.2 Unit tests

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

### 2.3 Integration tests

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

### 2.4 End-to-end gameplay scenario

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

### 2.5 Procedural-generation stress

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

### 2.6 Visual QA

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

### 2.7 Android/ADB smoke tests

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

## 3. Named regression scenarios

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

## 4. Feature-status rules

Maintain a feature matrix with columns such as `feature_id`, `implementation_status`, `unit_test`, `integration_test`, `desktop_e2e`, `emulator_test`, `physical_device_test`, `known_gaps`, and `evidence_path`.

Allowed statuses:

- `NOT_STARTED`
- `IN_PROGRESS`
- `IMPLEMENTED_NOT_VERIFIED`
- `VERIFIED`
- `BLOCKED`

Never mark a feature `VERIFIED` because it compiles, because a test was planned, or because the main menu opened. A feature is verified only to the scope supported by evidence. For example, `VERIFIED_DESKTOP` and `VERIFIED_ANDROID_EMULATOR` may be recorded as extra scope labels if useful; do not silently conflate them with physical device testing.

## 5. Performance budgets and device tiers

Use Low, Balanced, High, and Ultra profiles. Low reduces particles and lights, disables expensive screen distortion, simplifies reflections, and lowers update rates for offscreen entities. Balanced is the baseline mobile experience. High adds richer normal response, controlled caustics, and more atmosphere. Ultra enables the maximum supported effects but does not require hardware ray tracing.

Aim for 60 FPS on a tested mid-range device during ordinary exploration, with a configurable 30 FPS cap/fallback on weaker hardware or unusually expensive scenes. These are goals to validate, not a guarantee about every phone.

Profile at least: a dense biome, a large base, water plus fog, a cluster of active creatures, a market/settlement simulation update, a black-hole lensing encounter, a landing transition, and save/load with a large inventory. Record frame time, stutter, memory, draw calls/active lights where available, and time spent in expensive scripts. Put explicit limits on particle count and near-field simulation entities.

## 6. Required QA artifacts

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
