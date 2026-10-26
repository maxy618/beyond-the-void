# Android device smoke report

**Status: VERIFIED ON EMULATOR — smoke subset only. No physical device.**

Generated: 2026-10-26. Project: `D:\beyond-the-void`.

## Target

| Item | Value |
|---|---|
| AVD | `Medium_Phone_API_37.0` |
| Device serial | `emulator-5554` |
| Model | `sdk_gphone64_x86_64` |
| Android / API | 37 / 37 |
| Resolution / density | 1080 x 2400 / 420 dpi |
| Orientation observed | portrait, `ROTATION_0` |
| Renderer | Vulkan 1.2 Forward Mobile on SwiftShader |
| Emulator | 37.2.12.0, headless, `-gpu swiftshader_indirect` |
| APK | `build/android/BeyondTheVoid-debug.apk` |
| APK size / SHA256 | 58,777,638 bytes / `AB38B3011E21D68A7B378143E9D41C4A0D7865EDFCD16BEED42E1FA31301A3EF` |
| Package | `org.beyondthevoid.game` 0.1.0 (code 1) |

This is a software-rendered emulator. It is not evidence for real-device
GPU performance, thermals, battery use, or physical touch ergonomics.

## Build and install evidence

- Export succeeded (`EXPORT_EXIT=0`, `Signed`, `DONE`):
  `build/reports/android_export_attempt.log`
- `adb install -r` returned **Success**:
  `build/reports/adb_install.log`
- Explicit launch of `com.godot.game.GodotApp` is denied because it is not
  exported. The exported launcher alias was used:

```text
adb shell am start -W -n org.beyondthevoid.game/com.godot.game.GodotAppLauncher
```

- Launch status: `ok`, `COLD`; first measured total time after reinstall
  2067 ms. A later HOT relaunch took 227 ms. These are emulator startup
  measurements, not steady-state FPS.
- Logcat showed Godot 4.7.2 starting with the mobile renderer. No
  `FATAL EXCEPTION`, `E/AndroidRuntime`, `Force quitting Godot`, or script
  error was found. Full capture: `build/reports/android_logcat.txt`.

The Android immersive-mode confirmation overlay was displayed on first
launch and dismissed with a tap. The title screen then filled the portrait
display.

## Smoke path and evidence

Actions were driven with `adb shell input tap/keyevent`; the displayed
coordinates were 1080 x 2400.

1. **Title screen** rendered fullscreen in portrait.
   `screenshots/android_01_title.png`
2. **New Journey** opened the space view.
   `screenshots/android_02_space.png`
3. **Chart** opened; Vela showed landing clearance and Land/Jump controls.
   `screenshots/android_03_chart.png`
4. **Land** entered the Vela surface: objective, Kasa, Tidebreak, ship, and
   build pads visible.
   `screenshots/android_04_planet_tidebreak.png`
5. **Back** opened the field pause menu instead of quitting. Process PID 7302
   was unchanged before and after; logcat contained only
   `Invoking onMainBackPressed`, with no force-quit. Screenshot shows
   Resume / Save / Settings / Main menu.
   `screenshots/android_05_pause.png`
6. **Back again** closed pause and returned to the game; same PID 7302.
   `screenshots/android_06_resumed.png`
7. **Save** from pause showed `Field record saved`.
   `screenshots/android_07_saved.png`
   `run-as` inspection found `files/saves/slot_1.json` (3950 bytes) plus
   `settings.cfg`.
8. **Force-stop + relaunch**: Continue was enabled and the menu reported
   `A field record exists`. New PID 7688.
   `screenshots/android_08_continue_menu.png`
9. **Continue** loaded directly onto the Vela surface with the prior state.
   `screenshots/android_09_continued.png`
10. **HOME + relaunch**: process 7688 stayed alive; HOT relaunch took 227 ms
    and returned to the same planet state.
    `screenshots/android_10_resumed_lifecycle.png`

Back, save, Continue after process death, and HOME/relaunch are verified on
this emulator. Focus-loss input clearing, left-handed mode, text scaling,
quality presets, haptics, and sustained rendering have not been exercised on
Android.

## Regression suites after Android configuration changes

All ran after the final `project.godot` edits:

| Suite | Result |
|---|---|
| `tests/run_tests.gd` | 68 passed, 0 failed, 0 errors; 793 ms |
| `tools/validate_content.gd` | `CONTENT_OK=true`; 0 errors, 1 allowed dialogue-loop warning |
| `tools/generation_stress.gd` | 500/500 seeds, 9,000 nodes, 0 failures; 232 ms |
| `tests/ui_smoke.gd` | 52 checks, 0 failures, 16 screenshots |

These are desktop/headless results plus this emulator smoke. They do not
constitute a full Android gameplay playthrough.

## Limits and next checks

- No physical Android device was available.
- No full Android E2E: crafting, trading, building, ship changes, quest
  completion, and duplicate-reward checks were verified in the desktop E2E,
  not by Android UI automation.
- No rotation, low-memory, thermal, battery, or long-session test.
- SwiftShader performance is not representative of Adreno/Mali hardware.
- `aapt2` reports a missing `mipmap-anydpi-v26/themed_icon.xml` adaptive-icon
  resource. Install and launch still succeed; fix before store packaging.
- The APK is signed with a debug certificate and is not release-ready.
- Install `cmdline-tools`, NDK, CMake, and Gradle before attempting custom
  Gradle/native builds. The prebuilt-template debug export does not need them.

APK: `build/android/BeyondTheVoid-debug.apk`
