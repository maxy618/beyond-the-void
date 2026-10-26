# Environment manifest

Generated 2026-10-26. Project root: `D:\beyond-the-void`.

| Item | Value |
|---|---|
| OS | Microsoft Windows NT 10.0.26300.0 |
| CPU | Intel64 Family 6 Model 154 Stepping 3, GenuineIntel |
| RAM | 15.7 GB |
| Godot | 4.7.2.stable.official.ed1daf0bf |
| Godot console binary | `C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe` |
| Project renderer | Mobile |
| Project viewport | 720 x 1280, portrait |
| Git | 2.55.0.windows.5 |
| Branch / base commit | `main` / `6709f22d35837a1ed6a52a115fb24d35e8917117` (work uncommitted) |
| Node.js | v24.19.0 |
| npm | 11.17.0 |
| OpenCode | v2.1.4 |
| JDK | Eclipse Temurin OpenJDK 17.0.20.1 |
| JAVA_HOME | empty in persistent environment; set for export process only |
| Android SDK | `D:\android\sdk` |
| ANDROID_HOME | set |
| ANDROID_SDK_ROOT | empty in persistent environment; set for export process only |
| ADB | 1.0.41 (platform-tools 37.0.1) |
| Android build-tools | 36.0.0 |
| Android platform | android-37.0 |
| Android system image | android-37.0/google_apis_playstore/x86_64 |
| Android emulator | 37.2.12.0 |
| AVD | `Medium_Phone_API_37.0`, 1080 x 2400, 420 dpi, API 37 |
| Godot 4.7.2 export templates | present |
| Missing SDK components | cmdline-tools/sdkmanager, NDK, CMake, Gradle |
| Android device / emulator | emulator-5554 (x86_64, SwiftShader) |
| Debug APK | `build/android/BeyondTheVoid-debug.apk`, 58,777,638 bytes |
| APK SHA256 | `AB38B3011E21D68A7B378143E9D41C4A0D7865EDFCD16BEED42E1FA31301A3EF` |

## Verification commands

```powershell
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --headless --path D:\beyond-the-void --import
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --headless --path D:\beyond-the-void --script res://tests/run_tests.gd
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --path D:\beyond-the-void --script res://tests/ui_smoke.gd
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --headless --path D:\beyond-the-void --script res://tools/validate_content.gd
& 'C:\Users\maxim\AppData\Local\Godot\bin\Godot_v4.7.2-stable_win64_console.exe' --headless --path D:\beyond-the-void --script res://tools/generation_stress.gd
powershell -ExecutionPolicy Bypass -File tools\build_manifest.ps1
```

Android export used the same Godot binary with `--export-debug "Android Debug"`.
The full command and environment overrides are in `android_build.log`.

## Notes

- Android debug export, install, launch, Back, save/Continue, and HOME
  lifecycle were verified on the emulator. There is no physical-device
  evidence; see `device_smoke_report.md`.
- The emulator uses SwiftShader. Real GPU performance, thermal behavior, and
  battery use were not measured.
- Missing `cmdline-tools`, NDK, CMake, and Gradle block custom Gradle/native
  builds, not the prebuilt-template debug export.
- Desktop UI screenshots were produced by a real windowed Godot process at
  720 x 1280, 360 x 640, and 1080 x 2400. Android screenshots are separate
  1080 x 2400 emulator captures.
