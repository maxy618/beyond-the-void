# OpenCode, MCP, and Real Playtesting for Beyond the Void

## 1. The main principle

There is no single MCP server that magically validates an entire native game. A reliable Godot workflow combines static checks, content validation, unit/integration tests, a deterministic gameplay harness, Android build and device testing, visual inspection, and honest evidence reporting. MCP can let an agent control tools and observe a running app, but it does not replace deterministic tests or human judgment about whether the game feels good to play.

Use as few tool integrations as possible. Every MCP server adds tools and information to the agent's context; a large collection of overlapping servers can make the agent less effective, not more capable. Prefer a compact baseline and add a specialist only when a concrete gap justifies it.

## 2. Baseline toolchain

- **Godot 4.7.2 stable** is the initial version target for this pack. The official release archive identifies 4.7.2 stable as released on 18 August 2026. Verify the version installed on the machine and review official release notes before changing it. Do not upgrade to a beta/RC without an explicit compatibility reason.
- GDScript, with explicit types in save, quest, inventory, economy, content-validation, and generation code where that improves safety and clarity.
- Godot command-line/headless mode for import, parse, project smoke, data tests, and automated test runners.
- Android SDK, Platform Tools (`adb`), a compatible Java/JDK installation, and Godot export templates for the selected engine version.
- Git for checkpoints, reviewable diffs, rollback, and regression isolation. Preserve existing user work and the original HTML prototype.
- GdUnit4 or an equivalent framework for unit/integration tests, after verifying compatibility with the selected Godot release. Current GdUnit4 compatibility tables distinguish framework branches by supported Godot versions; select a compatible release instead of blindly installing latest.
- Android Emulator or a physical test device for platform acceptance. An emulator is useful, but it is not the same evidence as a physical phone.

Official references to verify when working:

- OpenCode MCP servers: https://dev.opencode.ai/v2/docs/mcp-servers/
- OpenCode configuration: https://opencode.ai/v2/docs/config
- Godot stable archive: https://godotengine.org/download/archive/4.7.2-stable/
- Godot Android export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Godot command-line tutorial: https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html
- Godot 2D glow/HDR information: https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html (find the current section on glow in 2D if the documentation structure has changed)
- GdUnit4 project and compatibility: https://github.com/godot-gdunit-labs/gdUnit4
- Android ADB reference: https://developer.android.com/tools/adb
- Android emulator documentation: https://developer.android.com/studio/run/emulator
- adb-mcp repository: https://github.com/iksnerd/adb-mcp
- Context7 MCP: https://mcp.context7.com/mcp

## 3. Required test loop: Godot CLI/headless

Use the command line to import assets, parse scripts, load scenes, validate content, exercise deterministic systems, and run test harnesses without opening the editor UI. Adapt the exact executable name and flags to the installed environment; do not assume `godot`, `godot4`, and a platform-specific binary are interchangeable.

Typical commands may resemble:

```bash
godot --headless --path . --editor --quit
godot --headless --path . --quit
```

These are examples only. The second command proves little by itself and is not a gameplay test. The project must provide dedicated test-runner entry points for unit tests, content lint, generation stress, and end-to-end harness scenarios. Capture exit codes and logs. A test command that silently does nothing is a failed test setup, not a pass.

## 4. GdUnit4 or another Godot test framework

Use the framework for inventory, recipe transactions, price calculations, generation constraints, dialogue and quest conditions, save serialization, migration, ship module compatibility, construction rules, and representative scene behavior. Verify the specific framework release supports the installed Godot version before adding it to the repo. Keep pure logic testable without requiring a live renderer whenever possible.

If framework installation becomes a blocker, start with a small first-party test harness and add a framework later. Do not leave tests unwritten simply because the preferred library is not available.

## 5. Android SDK and ADB

ADB is required for meaningful Android acceptance testing. Use it to inspect connected devices, install a debug APK, launch/stop the app, collect logcat, capture screenshots, check package state, and reproduce lifecycle events.

Verify the exact Java/JDK, Android SDK, platform-tools, target platforms, build tools, and export template requirements against the selected Godot documentation. Store paths in local editor settings/environment, not hardcoded in project files. Keep release-signing keystores and passwords out of Git and logs.

Test installation, launch, fixed portrait behavior, safe areas, touch input, system Back, pause/resume, process death/relaunch, save/load, shader/resource failures, and app crashes. If no emulator/device is available, run the tests that can run headlessly and mark device tests `BLOCKED`. Do not substitute a desktop window for an Android device test.

## 6. adb-mcp — useful but optional

The `adb-mcp` project provides an MCP server for Android emulators and connected devices through ADB. Its repository describes workflows for booting devices, screenshots, UI hierarchy observation, touch/swipe/text input, app lifecycle, logcat, and certain build/test tasks. It is a third-party independent project, not an official Godot or Google component.

Before installation:

1. Read the repository README, current release notes, license, and installation script.
2. Verify the expected OS/architecture, binary checksums, requirements, and whether the server supports the local OpenCode setup.
3. Inspect any shell script before executing it. Prefer a signed/release binary with a verified checksum or a reproducible build path.
4. Ensure Android SDK and ADB are available to the MCP process. A server running in a different environment/container may not be able to see the host's emulator.
5. Limit the tool to the devices and operations needed by the project. Avoid exposing a device or local service to the public network.
6. Test a low-risk workflow first: list devices, capture a screenshot, inspect the foreground app, and read logs before installing or interacting with the game.

Example commands and capabilities can change. Consult the repository at the time of installation rather than treating the following as immutable API promises: https://github.com/iksnerd/adb-mcp

## 7. OpenCode MCP configuration example

Current OpenCode v2 documentation places named servers under `mcp.servers`. The exact schema may change; check `opencode mcp list`, validate the config, and consult the documentation for the installed OpenCode release. Do not combine legacy and v2 shapes in one configuration.

Example `opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "context7": {
        "type": "remote",
        "url": "https://mcp.context7.com/mcp",
        "enabled": true
      },
      "android-adb": {
        "type": "local",
        "command": ["adb-mcp"],
        "enabled": true
      }
    }
  }
}
```

This is an example configuration, not a guarantee that both servers are installed or reachable. `adb-mcp` must exist in the environment's `PATH` or the command must use the correct absolute path. Context7 may require authentication or may not be necessary if the agent uses official documentation directly. Remove a server if the project does not need it.

Useful OpenCode commands include listing MCP connections and checking authentication, but verify exact CLI syntax against the installed version. Keep secrets in environment variables or the tool's auth flow. Never write bearer tokens or API keys directly into a checked-in config file.

## 8. Context7 — optional documentation lookup

Context7 can help an agent retrieve current API documentation for frameworks and libraries. It is optional. Prefer official Godot documentation and version-specific documentation pages for engine APIs. Do not use Context7 as a reason to accept an unverified API call; compile and test the code against the installed version.

## 9. Godot editor bridges and other MCP servers

A Godot editor bridge or scene-inspection MCP can be useful for inspecting a live scene tree, reading node state, or helping the agent understand a visual issue. Treat it as optional and third-party unless it is shipped by the official engine. Verify version compatibility, access scope, license, network binding, and security posture before enabling it. Do not let an unfamiliar bridge perform massive scene changes without reviewing the resulting diff.

Use Playwright only for an actual web surface, such as a content-authoring panel, website, or HTML prototype. Playwright is not evidence that the native Godot APK works correctly, and it is not a replacement for ADB-driven native interaction.

## 10. How the agent must playtest for real

The game should expose a deterministic debug/test harness available only in debug and test builds. It should support starting from a known save/seed, selecting a stable world/entity by ID, performing supported actions, checking state snapshots, and emitting machine-readable outcomes. Release builds must not expose developer cheats or unprotected test commands.

Use a loop of **observe → locate → act → re-observe**. Capture a screenshot, inspect the UI hierarchy where supported, use a stable element ID or accessible label when possible, act, then capture again to confirm the expected result. Do not assume a tap succeeded because a command returned without error.

A full automated playthrough should be able to:

1. create a fresh save;
2. fly and land;
3. observe lifeforms and save catalogue evidence;
4. gather and refine resources;
5. craft an item;
6. accept and progress a mission;
7. trade with a finite-stock market;
8. build and power a base module;
9. change a ship module;
10. trigger and safely navigate a controlled anomaly encounter;
11. save, terminate, restart, and verify every relevant state;
12. capture screenshots and logs at failure points.

Use stable world IDs in deterministic tests. Coordinate taps are appropriate for validating touch layout, but they are brittle for deep logic and should not be the only test mechanism. For every failure, preserve a seed, build version, logs, screenshot, failing step, expected state, and actual state.

## 11. Minimum release gates

1. The project imports and scripts parse without errors in the pinned Godot version.
2. Every JSON/content pack validates; every required referenced ID resolves.
3. Same seed and generator version reproduce the same world; different seeds vary within valid constraints.
4. Economy tests rule out unintended infinite money/item loops and enforce stock/currency bounds.
5. Crafting is atomic and cannot lose materials on failure or duplicate outputs on repeated input.
6. Quest rewards are idempotent and do not duplicate after reload or app resume.
7. Save round-trip works and at least one previous schema migrates safely.
8. The vertical-slice E2E loop passes through save/reload.
9. APK installation and portrait touch smoke test pass on the Android environment actually used.
10. Test reports list the actual device/emulator, API level, resolution, engine version, renderer/preset, build identifier, commands, result, and outstanding gaps.
11. Every unavailable device test is marked `BLOCKED`, not `PASS`.
12. The release build contains no debug cheats, signing secrets, or unapproved network behavior.

## 12. Security and maintenance hygiene

- Give MCP tools only the permissions needed for the task; prefer local-only listeners and stdio integrations when appropriate.
- Do not place tokens, passwords, signing keys, or private device details in Git, prompts, or logs.
- Do not enable telemetry, upload builds, publish releases, or send project files to third-party services without explicit authorization.
- Review Git diffs, changed files, dependency licenses, and generated files after each phase.
- Run the full relevant test suite after integrating parallel-agent work.
- Never claim the physical device was tested if only headless or emulator tests ran.
- Record the environment and commands needed to reproduce a release build. A toolchain that only works on an agent's undocumented machine is not a finished build pipeline.

## 13. Suggested division of labor when using subagents

If the selected OpenCode/model setup supports subagents, delegate only work that can proceed independently. Good examples are: one agent auditing existing architecture and toolchain, one authoring a validated narrative data pack, one reviewing schemas and test coverage, and one investigating renderer/performance constraints. Keep one lead agent responsible for decisions, file ownership, integration, and acceptance gates.

Do not allow several agents to edit the same central state service, save schema, content registry, or quest engine simultaneously. Ask each subagent for a bounded deliverable: a report, a separate branch, or isolated files. The lead agent must review diffs, resolve conflicts, run validation, and rerun relevant tests after integration. Subagent reports are not evidence until the artifacts and tests have been inspected.

## 14. Reproducibility checklist

A useful test report includes:

- repository commit or working-tree identifier;
- Godot/editor version and export-template version;
- host OS and versions of Java/JDK, Android SDK, platform-tools, and emulator;
- device/emulator model, Android API level, screen resolution/density, and renderer when known;
- content-pack and save-schema versions;
- random seed bundle and world/mission IDs;
- exact command lines or automation scenario IDs;
- exit codes and summarized logs;
- screenshots/video files for visual failures;
- observed versus expected behavior;
- known issues and checks blocked by unavailable hardware/tooling.

Do not include secrets, account identifiers, private paths containing personal data, or unnecessary device identifiers. Where a report is shared externally, redact the environment accordingly.

## 15. Current-version caution

The URLs above are starting points, not a license to assume that a tool's API or schema has not changed. Before adding or invoking an integration, read the current official documentation or the project's repository, check the installed version, validate the configuration, and run a minimal smoke test. In particular, distinguish OpenCode's current `mcp.servers` configuration shape from older examples that placed server names directly beneath `mcp`. Do not mix configuration schemas from different OpenCode generations.
