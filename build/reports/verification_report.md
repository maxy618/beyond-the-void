# Beyond the Void — vertical slice verification report

Generated: 2026-10-26

Repository: `D:\beyond-the-void`

Branch / base commit: `main` / `6709f22` (all game work is uncommitted)

## Result

A playable portrait vertical slice exists. Desktop/headless checks pass, and a
debug APK builds, installs, launches, and survives Back, save/Continue, and
HOME/relaunch smoke checks on an Android API 37 emulator. Physical-device
validation and a full Android gameplay E2E are still outstanding.

## Status

| Area | Status | Evidence |
|---|---|---|
| Repository audit and Godot 4.7.2 import | VERIFIED | `headless_import.log`, no parse errors |
| External content pack and manifest | VERIFIED | `content_validation.json`, 0 errors, 1 allowed dialogue-loop warning |
| Content counts and cross-references | VERIFIED | 16 items, 10 recipes, 24 species (12 flora + 12 fauna), 4 hulls, 6 modules, 4 buildings, 2 quests, 1 dialogue, 1 market |
| Inventory, atomic crafting, rollback | VERIFIED | 68-test suite |
| Finite-stock market | VERIFIED | buy/sell, stock, bounded integer prices, insufficient credits/capacity |
| Ecology observation, harvest, recovery, nonlethal calming | VERIFIED | 24 species records; population and observation tests |
| Quests, dialogue conditions, idempotent rewards | VERIFIED | prologue and side quest tests; condition recheck at commit |
| Base building, power, production | VERIFIED | power cell + smelter produces alloy over time |
| Ship loadout, stats, cargo capacity, jump/fuel | VERIFIED | cargo pods change capacity; jump consumes fuel |
| Save schema v2, v1 migration, atomic write, backup fallback | VERIFIED | roundtrip, corrupt primary, interrupted temp, missing pack, future schema |
| Deterministic desktop E2E, save → new session → restore | VERIFIED | `e2e_vertical_slice.json`, 52 assertions |
| 500-seed generation stress | VERIFIED | `generation_stress.json`, 500/500 |
| Portrait rendered UI, main game actions | VERIFIED on desktop | `ui_smoke.json`, 52 checks, 16 screenshots |
| Android debug APK export | VERIFIED | `android_build.log`, `android_export_attempt.log` |
| APK signature and alignment | VERIFIED | apksigner v2/v3, zipalign 4 |
| Android emulator install, launch, Back, save/Continue, HOME lifecycle | VERIFIED on emulator | `device_smoke_report.md`, 10 Android screenshots |
| Physical Android device / real GPU | BLOCKED | no physical device; emulator uses SwiftShader |
| Full Android gameplay E2E | NOT_STARTED | Android smoke is a navigation/lifecycle subset |
| Release signing / Play Store packaging | NOT_STARTED | debug APK only |
| Final art, shaders, audio, later campaign acts | IN_PROGRESS / NOT_STARTED | see `known_issues.md` |

## Android build

- Godot `4.7.2.stable.official.ed1daf0bf`.
- Prebuilt Android export templates present.
- JDK: Eclipse Temurin 17.0.20.1.
- Android SDK: `D:\android\sdk`; ADB 37.0.1; build-tools 36.0.0; API 37
  platform and x86_64 system image.
- Missing SDK pieces: `cmdline-tools`/`sdkmanager`, NDK, CMake, Gradle. These
  do not block the prebuilt-template debug export.
- Preset: `Android Debug`, package `org.beyondthevoid.game`, version 0.1.0
  (code 1), arm64-v8a + x86_64, debug signing only.
- Required project settings: `import_etc2_astc=true` and
  `config/quit_on_go_back=false`.
- APK: `build/android/BeyondTheVoid-debug.apk`
  - 58,777,638 bytes
  - SHA256 `AB38B3011E21D68A7B378143E9D41C4A0D7865EDFCD16BEED42E1FA31301A3EF`
  - minSdk 24, target/compile SDK 36, portrait manifest, launcher alias
    `com.godot.game.GodotAppLauncher`
  - Signer: Godot debug certificate; not release-ready.

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot'
$env:ANDROID_HOME = 'D:\android\sdk'
$env:ANDROID_SDK_ROOT = 'D:\android\sdk'
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' `
  --headless --path D:\beyond-the-void `
  --export-debug "Android Debug" build/android/BeyondTheVoid-debug.apk
# EXPORT_EXIT=0, Signed, DONE
```

## Automated commands and results

```powershell
# Import and parse
Godot_v4.7.2-stable_win64_console.exe --headless --path D:\beyond-the-void --import
# exit 0; no script/parse errors

# Domain + integration
Godot_v4.7.2-stable_win64_console.exe --headless --path D:\beyond-the-void --script res://tests/run_tests.gd
# TESTS run=68 passed=68 failed=0 errors=0 duration_ms=793

# Real windowed portrait UI
Godot_v4.7.2-stable_win64_console.exe --path D:\beyond-the-void --script res://tests/ui_smoke.gd
# UI_SMOKE checks=52 failures=0 screenshots=16

# Content validation
Godot_v4.7.2-stable_win64_console.exe --headless --path D:\beyond-the-void --script res://tools/validate_content.gd
# CONTENT_OK=true

# Deterministic generation stress
Godot_v4.7.2-stable_win64_console.exe --headless --path D:\beyond-the-void --script res://tools/generation_stress.gd
# GENERATION_STRESS seeds=500 failed=0 nodes=9000 duration_ms=232
```

Android smoke:

```text
adb install -r build/android/BeyondTheVoid-debug.apk        -> Success
adb shell am start -W -n org.beyondthevoid.game/com.godot.game.GodotAppLauncher
                                                            -> Status: ok, COLD 2067 ms
KEYCODE_BACK                                                -> pause menu, PID unchanged, no force-quit
KEYCODE_BACK                                                -> resume, same PID
Save from pause                                             -> files/saves/slot_1.json (3950 bytes)
am force-stop + relaunch                                    -> Continue enabled, new PID
Continue                                                    -> Vela surface state restored
HOME + relaunch                                             -> same PID, HOT 227 ms
```

No `FATAL EXCEPTION`, `E/AndroidRuntime`, `Force quitting Godot`, or script
error was found in `build/reports/android_logcat.txt`.

## Vertical-slice flow covered by the desktop E2E

Fresh session → prologue active → travel/land on Vela → observe flora and fauna
→ harvest fiber → refine and craft a signal lens → buy/sell at the finite
market → speak with Kasa → calibrate lens → restore relay → complete quest and
claim reward once → build power cell and smelter → powered production → equip
cargo pods → save → terminate session → load new session → verify location,
credits, inventory, quests, facts, ship capacity, buildings, market stock,
ecology, observations, journal → duplicate claim rejected.

## Android smoke path

Title → New Journey → space → Chart → land on Vela → Back pause → Back resume
→ Save → force-stop → Continue → HOME → relaunch.

Screenshots: `build/reports/screenshots/android_01_title.png` through
`android_10_resumed_lifecycle.png`. Desktop screenshots:
`build/reports/screenshots/01_title_720x1280.png` through
`16_planet_1080x2400.png`.

## Reports

- `headless_import.log`
- `unit_tests.json`, `unit_tests.xml`
- `integration_tests.json`, `e2e_vertical_slice.json`
- `content_validation.json`
- `generation_stress.json`
- `ui_smoke.json`
- `android_build.log`, `android_export_attempt.log`, `android_apk_badging.log`,
  `android_manifest_tree.log`, `adb_install.log`, `android_logcat.txt`
- `device_smoke_report.md`
- `environment_manifest.md`
- `performance_summary.md`
- `known_issues.md`

## Defects and limits

See `known_issues.md`. The most important are: no physical Android device or
real-GPU evidence; Android smoke is not a full gameplay E2E; release signing and
store packaging are unfinished; the themed adaptive-icon resource is missing
from the APK; final art/audio/shaders and later campaign acts are incomplete;
only English is shipped; and the test runner emits benign cleanup warnings.

No physical Android device, real-device performance, or release production
readiness is claimed.
