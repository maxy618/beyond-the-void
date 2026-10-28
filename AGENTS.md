# AGENTS.md — Beyond the Void

Permanent operating rules for every agent working in this repository. These rules override
convenience, speed and optimistic assumptions. They do not override the user's explicit
instructions for a given task.

## 0. Project facts

- Godot **4.7.2**, portrait-first mobile game, main scene `res://scenes/main.tscn`.
- Project root: `D:\beyond-the-void`.
- Godot console binary:
  `C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe`
- Authoritative design reference: `docs/beyond_the_void_spec/` — **read-only, never delete**.
- Approved overhaul plan: `.opencode/plans/beyond-the-void-overhaul.md`.
- Android SDK/adb: `D:\android\sdk\platform-tools\adb.exe`, emulator `Medium_Phone_API_37.0`.
- Evidence lives in `build/reports/overhaul/`. Do not scatter reports elsewhere.

## 1. Non-negotiables

1. Never delete the repository, `docs/beyond_the_void_spec/`, or user work.
2. Never remove an existing system until its dependencies are understood, its replacement is
   implemented, and the replacement is verified.
3. **Never claim untested functionality works.** Compiling, exporting, or passing a unit test is
   not proof that a player-facing interaction works.
4. Every result is labelled exactly one of:
   - **PASS** — with a link/path to evidence.
   - **FAIL** — with exact reproduction steps.
   - **BLOCKED** — with the missing prerequisite.
   - **NOT TESTED** — with the reason.
5. No secrets, tokens, keystores, APKs, `.godot/` or import caches in git.
6. No software installation or system-wide change without explicit permission.
7. No force-push, no history rewrite, no silent push failure.

## 2. Shell and tooling

- Shell is non-interactive (no TTY). Always use non-interactive flags; never launch editors,
  pagers or REPLs that wait for input.
- Use dedicated read/write/edit tools for files; use the shell for builds, tests, git, adb.
- Headless domain tests:
  `& $G --headless --path D:\beyond-the-void --script res://tests/run_tests.gd`
- Windowed UI/playtest runs must **not** use `--headless`; they render real frames.
- Always scan stdout/stderr for `ERROR`, `SCRIPT ERROR`, parse failures and physics warnings.

## 3. Hands-on gameplay testing is mandatory

Source review and headless tests never substitute for playing the game.

### 3.1 Godot MCP (primary evidence)

- Addon lives in `addons/godot_mcp` when enabled; server is `@satelliteoflove/godot-mcp`.
- Connection target: `ws://127.0.0.1:6550`.
- Start the **editor** with the project, then drive the running game:
  - `godot_editor_edit` — run/stop the project, select nodes, rescan.
  - `godot_input` — real actions, keys, mouse and touch input.
  - `godot_game_time` — freeze and step time for reproducible observation.
  - `godot_runtime_state` — entity/state digests, camera/audio state.
  - `godot_editor_read` — runtime logs, editor logs, screenshots.
  - `godot_profiler` — frame-time evidence.
- If MCP is disconnected, diagnose (`addons/`, `[editor_plugins]`, port, editor log), record the
  exact blocker, continue with other verification, and mark MCP-only checks **BLOCKED**.
  Never imply MCP was used when it was not.

### 3.2 Per-mechanic protocol (required)

1. Start from a known, stated state.
2. Perform the input a real player would perform.
3. Observe the actual response on screen.
4. Verify the underlying state change.
5. Capture a screenshot when visual feedback matters, then **look at it** and describe defects.
6. Check runtime logs.
7. Reproduce and fix any failure.
8. Retest the original failure **and** related flows.

### 3.3 Android (ADB)

```
D:\android\sdk\platform-tools\adb.exe devices
D:\android\sdk\platform-tools\adb.exe install -r build\android\BeyondTheVoid-debug.apk
D:\android\sdk\platform-tools\adb.exe shell am start -n org.beyondthevoid.game/com.godot.game.GodotApp
D:\android\sdk\platform-tools\adb.exe logcat -d -s godot:V AndroidRuntime:E
D:\android\sdk\platform-tools\adb.exe exec-out screencap -p > build\reports\overhaul\android\shot.png
```

- Emulator input cannot prove true concurrent multi-touch. If it cannot synthesize it, report
  Android multi-touch as **BLOCKED** with the tool limitation. Testing each stick separately is
  not evidence of concurrency.

## 4. Evidence and honesty

- Screenshots/reports: `build/reports/overhaul/<stage>/`.
- A visual review must name specific defects (clipping, overlap, scale, contrast, placeholder
  art, camera fault, confusing state) and the fix. "Screenshot captured" is not a review.
- Reports state what was exercised, how, and what remains unverified.
- No claim of "production-ready", "complete" or "polished" beyond the evidence.
- Milestone 1 (Vela vertical slice + engines) is not the finished game; say so.

## 5. Camera rules

- One `CameraDirector` owns the only `Camera2D`. Gameplay code never sets zoom directly.
- Modes: on-foot, sprint, aim, jetpack, surface flight low/high, space cruise/combat, orbit scan,
  entry, landing, event scale, cinematic. Transitions are critically damped, never stepped.
- Large-body framing derives from object size and distance, not hard-coded zoom constants.
- Aim direction is computed in world space before smoothing and is never biased by zoom or shake.
- Camera render position snaps to the world pixel grid; aim math does not.
- Shake uses a trauma model with independent sources, decay, intensity setting and reduced-motion
  support. Ordinary walking does not shake.
- The player stays readable during normal play; no speck-sized player, no void beyond bounds.

## 6. Rendering rules

- World renders in a low-resolution `SubViewport`; UI stays on a native-resolution `CanvasLayer`.
- Nearest-neighbour filtering, integer scaling, pixel snapping. No bilinear world scaling.
- Pixel density is configurable (Auto/1x/2x/3x); changing it must not change gameplay, touch
  targets, collision or coordinates.
- Adaptive resolution uses a smoothed frame-time window with hysteresis and cooldown; no flicker.
- Low/Medium/High/Ultra must visibly and measurably differ (glow, lights, particles, parallax,
  haze, shadows). Capture the same location at every preset.
- No indiscriminate full-screen filter stacks that muddy the pixel art.

## 7. Audio rules

- `AudioManager` buses: Master, Music, SFX, Ambience, Dialogue, UI, Ship, Combat.
- Every meaningful action has a registered event in `content/audio/events.json` or a documented
  reason for silence.
- MusicDirector transitions are state-driven, bar-quantized and debounced; no stale loops across
  pause, save or scene changes.
- The agent cannot hear rendered audio. Technical checks (RMS/peaks, event IDs, loop continuity,
  voice counts) are **not** acoustic approval. Listening is **BLOCKED** until a human reviews it.
- Record asset provenance and mark each asset draft or final.

## 8. Procedural generation rules

- Deterministic: same seed + same generator version → same output, on every platform.
- Stable IDs derive from indices, never from hashes. Saves store deltas and IDs, never generated
  geometry.
- No global RNG, wall-clock time, OS data or dictionary iteration order in generation.
- Changing a generator requires a version bump and reviewed golden-fixture update.
- Generation must respect memory bounds and a per-chunk time budget.
- Visual audits are separate from automated assertions and are required at gameplay scale.

## 9. Art rules

- Characters, props, ships, structures, flora, fauna and icons are authored pixel maps or
  compositions of authored parts. No circles/polygons/vector line art as finished world content.
- Palettes are coherent per biome, ≤12 colours plus outline; top-left light; 1 px outline; no
  anti-aliasing; no stray pixels.
- Every asset is inspected at gameplay scale (720×1280 and 1080×2400) and in contact sheets.
- `tools/art_audit.gd` and a primitive-usage grep gate must pass before art is called finished.
- Assets below the bar are labelled stylized prototypes with a defined artist-production pass.

## 10. Git and GitHub

- Work on `overhaul/procedural-universe`; `main` holds the verified baseline checkpoint.
- Commit after each stage gate with a conventional message; push after each gate.
- Open/keep a draft PR and one issue per stage with acceptance criteria.
- `gh` is **not installed** and must not be installed without permission. Use git for
  branch/commit/push and the GitHub web UI/API for issues/PR. If credentials are missing, report
  the exact blocker; do not fake success.
- CI: `.github/workflows/ci.yml` runs headless tests, content validation, generation smoke, scene
  validation and art audit, and uploads reports/contact sheets as artifacts.
- Never commit generated caches, APKs, secrets or machine-specific files.

## 11. Before saying "done"

- Re-run the relevant suites fresh; quote real numbers.
- Inspect the final diff for accidental deletions and unrelated changes.
- List every claimed feature with its evidence, every failure with reproduction, every blocked
  check with its prerequisite, and the known quality limitations.

## Vision and test consultation (permanent)
The primary agent ALWAYS consults the designated visual QA artist on every visual change and every visual test. It hands over real gameplay captures and animation clips; an unreviewed screenshot is not evidence. The artist's verdict is binding: exact file or capture, named defect, required fix. The primary fixes and re-submits.
Parallel artist sessions are allowed only on completely disjoint asset sets with declared ownership; never let two sessions edit the same file. The primary waits for all sessions and integrates their work.