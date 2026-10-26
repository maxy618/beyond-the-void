# Performance summary

Desktop Windows measurements plus Android emulator launch timings only.
**No FPS, frame time, GPU, thermal, or battery performance was measured.**

| Measurement | Result |
|---|---|
| Headless domain/integration suite | 68 tests in 793 ms |
| Content validation | 11 ms |
| 500-seed generation stress | 232 ms total, 9,000 ecology nodes, 0 failures |
| Windowed UI smoke | 52 checks, 16 screenshots, 0 failures |
| APK cold launch, API 37 emulator | 2067 ms (first measurement after reinstall) |
| APK HOT relaunch, API 37 emulator | 227 ms |
| APK size | 58,777,638 bytes |

## Source files

- `unit_tests.json`, `integration_tests.json`, `e2e_vertical_slice.json`
- `content_validation.json`
- `generation_stress.json`
- `ui_smoke.json`
- `android_build.log`, `android_logcat.txt`, `device_smoke_report.md`

## Limits

- The emulator uses SwiftShader software rendering. Launch timings are not
  representative of Adreno/Mali hardware.
- Headless timing is not frame time. No FPS, frame pacing, memory, thermal, or
  battery data exists.
- The desktop UI images are software-window captures, not Android GPU captures.
- Quality tiers currently gate particle counts and animation, not shader cost.
  They are not a hardware performance guarantee.
- UI smoke does not measure startup time; Android startup was measured
  manually with `am start -W`.
- The test runner reports benign ObjectDB/resource cleanup warnings at process
  exit; all assertions complete before exit.
