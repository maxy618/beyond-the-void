# Beyond the Void

A portrait-first 2D sci-fi exploration vertical slice made with Godot 4.7.2. Ari Vale follows a signal from her missing sister to the mist moon Vela. Observe, gather, craft, trade, build, and repair without stripping the ecosystem bare.

## Run

```powershell
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --path D:\beyond-the-void
```

The project starts at `scenes/main.tscn`. Base viewport is 720 x 1280, portrait, mobile renderer.

## Verify

```powershell
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --headless --path D:\beyond-the-void --script res://tests/run_tests.gd
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --path D:\beyond-the-void --script res://tests/ui_smoke.gd
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --headless --path D:\beyond-the-void --script res://tools/validate_content.gd
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --headless --path D:\beyond-the-void --script res://tools/generation_stress.gd
```

Reports and screenshots land in `build/reports/`.

## Content

All game records live in `content/` as versioned JSON with stable IDs. After editing content, rebuild the manifest:

```powershell
powershell -ExecutionPolicy Bypass -File tools\build_manifest.ps1
```

English strings are in `content/localization/en/`. UI and content code read keys from the loaded locale, not hardcoded display names.

## Layout

- `scenes/` main scene
- `scripts/core/` session, registry, validation, localization, save service
- `scripts/systems/` inventory, crafting, market, quests, dialogue, ecology, building, ships
- `scripts/world/` deterministic generation
- `scripts/ui/` portrait UI, panels, renderers, touch controls
- `scripts/tests/` first-party suite
- `tests/` headless runner and windowed smoke
- `tools/` manifest builder, content validation, generation stress

## Android status

A debug APK is built and was installed, launched, and smoke-tested on an Android
API 37 x86_64 emulator: portrait title/space/chart/landing, Back pause/resume,
save, Continue after force-stop, and HOME/relaunch. No physical Android device
was available, so real-GPU, thermal, battery, and hardware-touch behavior remain
unverified.

APK: `build/android/BeyondTheVoid-debug.apk` (debug-signed, not store-ready).
Details: `build/reports/android_build.log`, `build/reports/device_smoke_report.md`.

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot'
$env:ANDROID_HOME = 'D:\android\sdk'
$env:ANDROID_SDK_ROOT = 'D:\android\sdk'
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' `
  --headless --path D:\beyond-the-void `
  --export-debug "Android Debug" build/android/BeyondTheVoid-debug.apk
```

The debug export uses the prebuilt Godot template. `cmdline-tools`, NDK, CMake,
and Gradle are not installed, so custom Gradle/native builds are not available.

`docs/beyond_the_void_spec/` is the read-only specification library and is not part of the game runtime.
