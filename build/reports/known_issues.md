# Known issues

Generated 2026-10-26.

## Android validation gaps

1. **No physical Android device evidence.** The debug APK was built, installed,
   launched, and smoke-tested on an API 37 x86_64 emulator using SwiftShader.
   Real Adreno/Mali GPU behavior, thermals, battery use, memory pressure, and
   physical touch ergonomics are unverified.
2. **No full Android gameplay E2E.** Android smoke covers title, space, chart,
   landing, Back/pause/resume, save, Continue after force-stop, and HOME
   lifecycle. Crafting, trading, building, ship changes, quest completion, and
   duplicate-reward checks were verified in the desktop E2E only.
3. **Not all Android UI settings were exercised.** Back/pause and basic
   fullscreen portrait rendering are verified on the emulator. Focus-loss input
   clearing, left-handed layout, text scaling, quality presets, reduced motion,
   haptics, display cutouts/safe-area insets, rotation behavior, and
   low-density touch sizing are not.
4. **The APK is debug-signed.** Signer is the Godot debug certificate; no
   release keystore, release export, Play Store packaging, or production
   signing exists. The debug certificate is replaceable and not a secret.
5. **Themed icon warning.** `aapt2` reports a missing
   `res/mipmap-anydpi-v26/themed_icon.xml` adaptive-icon resource. Install and
   launch succeed; fix before store packaging.
6. **Missing Android SDK components.** `cmdline-tools`/`sdkmanager`, NDK,
   CMake, and Gradle are absent. The prebuilt-template debug export works, but
   custom Gradle builds, native plugins, and release optimization cannot be
   tested until they are installed.

## Touch and layout

7. Touch targets are designed at 50–54 px at the 720 x 1280 base viewport. At a
   360 x 640 physical window the whole canvas is scaled down, so physical
   targets become small; low-density devices were not tuned separately.
8. The 360 x 640 screenshot is a scaled render of the 720 x 1280 base canvas.
   It fits, but text and controls are physically small at that size.

## Visual / content scope

9. The vertical slice uses code-drawn stylized placeholder art. Water caustics,
   lensing shaders, particle lighting, audio, and final art are not implemented.
10. English is the only locale. Localization keys and the locale manifest are in
    place for translation packs.
11. Content covers 16 items, 10 recipes, 24 species, 4 hulls, 6 ship modules,
    4 buildings, 2 quests, 1 dialogue, 1 market, 2 systems, and 5 planets. This
    meets the vertical-slice minimum, not the later 80-item / 40-recipe /
    30-flora / 30-fauna target.
12. Fauna behavior is represented by distinct content records plus visual
    motion cues; there is no autonomous roaming, pathfinding, or full ethology
    state machine yet. Observation, nonlethal calming, population loss, and
    recovery are simulated.

## Technical debt

13. The test runner leaks ObjectDB instances and 10 resources at process exit
    because domain services form reference cycles. Assertions and reports are
    complete; cleanup is unpolished.
14. Save backup keeps one previous generation only. Interrupted-write recovery
    and corrupt-primary fallback are tested, but multi-generation backup
    rotation is not.
15. Removed/retired content IDs are detected and the save is rejected rather
    than remapped. A content-redirect migration table is not implemented.
16. The manifest must be regenerated manually after content changes with
    `powershell -ExecutionPolicy Bypass -File tools\build_manifest.ps1`.
17. No CI pipeline is configured; all checks were run locally.
18. No audio system, accessibility screen-reader pass, or gamepad remapping UI
    exists yet.
19. The Android export preset is debug-only and excluded APK output lives under
    `build/android/`. Release packaging and signing are unfinished.
