# Stage 0 — Verified baseline

Date: 2026-10-26
Repository: `D:\beyond-the-void`
Branch: `main` @ `6709f22`
Approved plan: `.opencode/plans/beyond-the-void-overhaul.md`
(SHA256 `4ECA6CE1032EC91386CAC325828D1D0D30E673F5A462FDE0E214528CC5F5E94C`)

All results below were produced fresh in this session. Historical reports were not reused.

## Automated baseline

| Check | Result | Number | Evidence |
|---|---|---|---|
| Domain + integration | PASS | 68/68 passed, 0 failed, 0 errors, 1333 ms | `baseline/domain_tests.log`, `build/reports/unit_tests.json` |
| Content validation | PASS | 16 items, 10 recipes, 24 species, 4 hulls, 6 modules, 1 market, 2 quests, 1 dialogue, 4 buildings, 5 planets, 2 systems, 1 settlement, 1 ecology, 3 tool modes | `baseline/content_validation.log` |
| Generation stress | PASS | 500/500 seeds, 9,000 nodes, 0 failed, 242 ms | `baseline/generation_stress.log` |
| UI smoke | PASS | 52/52 checks, 0 failures, 16 screenshots | `baseline/ui_smoke.log`, `baseline/ui_smoke.json` |

Allowed pre-existing warning: `dialogue.npc.kasa` contains a dialogue loop through `start -> relay -> relay_how`. No content errors.

Pre-existing engine warnings: 461 ObjectDB instances and 10 resources still in use at exit after domain tests; 21 ObjectDB instances and 10 resources after UI smoke. These do not fail the suites and must be re-checked once the presentation layer is rebuilt.

## Hands-on tooling

Godot MCP is **PASS / connected** after enabling the addon:

- Addon copied to `addons/godot_mcp` (v4.1.11) and registered in `project.godot` under `[editor_plugins]`.
- The editor must be launched with the console binary; the windowed binary detached without starting the plugin:
  `Godot_v4.7.2-stable_win64_console.exe --editor --path D:\beyond-the-void`
- `[godot-mcp] Server listening on 127.0.0.1:6550` confirmed in the editor log.
- A stale second MCP client held the single-client bridge and rejected connections. Killing the stale `node` client freed it; the working client then connected.
- `godot_project get_info` returned the project path, name and main scene.
- `godot_editor_edit run` launched the real game; `godot_editor_read get_state` reported `is_playing: true`; `godot_runtime_state digest` returned the live Control tree; `godot_editor_read screenshot_game` returned a real 540x960 frame.

## Visual baseline review

Screenshots: `baseline/screenshots/` (26 files, including 720x1280, 360x640 and 1080x2400 captures).

### Title (`01_title_720x1280.png`, MCP frame)
- Flat starfield backdrop; the only identity element is a thin ring behind the wordmark.
- Buttons are generic rounded rectangles; "Continue" sits above a very faint caption, so availability is hard to read at a glance.
- No save summary, no location, no time, no credits. The screen does not yet communicate a sci-fi game.

### Space (`02_space.png`)
- The system is a decorative orbit diagram: planets are flat two-tone circles, the star is concentric rings, and there is no ship model.
- The player cannot fly: the only travel path is opening the Chart and selecting a planet.
- Permanent 252 px bottom dock takes roughly 20% of the screen and mixes tool modes with navigation.
- "Interact" is shown disabled with no explanation of what is missing.
- HUD is text-heavy (`120 cr  5/80 kg  Fuel 80`) with no bars or iconography.

### Surface (`04_planet_tidebreak.png`)
- World content is translucent circles standing in for terrain, foliage and rocks; the player is a handful of pixels labelled "SKIN" and is nearly invisible.
- No pixel-art assets, no biome composition, no collision, no depth sorting.
- The joystick overlaps the dock; there is no aim stick and no sprint/jetpack/use controls.
- Objective, credits, mass and fuel occupy the top strip while the bottom strip consumes a quarter of the play area: the world is framed as a diagram, not a place.

These defects are the baseline the overhaul must replace; they are not accepted as final art or final UI.

## Repository hygiene

- `.gitignore` now excludes APK/AAB outputs, build caches, the locally installed MCP addon, `.serena/` and keystores. Evidence reports and screenshots remain tracked.
- CI added at `.github/workflows/ci.yml`: pinned Godot 4.7.2, project import, domain/integration tests, content validation, generation stress, report artifact upload.
- Issue and pull-request templates added with explicit PASS / FAIL / BLOCKED / NOT TESTED evidence fields.

## Labeled status

| Item | Status |
|---|---|
| Fresh automated baseline | PASS |
| MCP editor + runtime connection | PASS |
| MCP input injection | NOT TESTED (no movement yet; Stage 1 gate) |
| Baseline screenshots captured | PASS |
| Baseline screenshots visually reviewed | PASS (defects listed above) |
| Android emulator | NOT TESTED this stage (previous APK evidence is historical) |
| Physical Android device | BLOCKED (no device available) |
| Audio listening | BLOCKED (agent cannot hear rendered output) |
