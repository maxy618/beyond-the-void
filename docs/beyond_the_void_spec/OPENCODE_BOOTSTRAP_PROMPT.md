# Short OpenCode Bootstrap Prompt — Beyond the Void

Use this message after the specification pack has been placed in the repository as described below.

---

Work on **Beyond the Void** in the current open repository.

## Workspace boundaries are mandatory

I have placed the specification and reference documents in:

`docs/beyond_the_void_spec/`

This folder is the authoritative **specification library only**. The **current repository root is the actual game workspace**. Create and edit the Godot project, scenes, scripts, resources, production content, tests, build scripts, and generated reports in the repository's real project directories, never inside `docs/beyond_the_void_spec/`.

Before changing files, identify the actual repository root, inspect `git status`, and review the complete project tree. Preserve existing work. Do not create a nested second Godot project inside the documentation folder. Do not move or delete the specification. If the repository already has a valid project structure, adapt to it rather than replacing it with an example tree.

## Read the complete specification

Read all of the following before implementing gameplay:

1. `docs/beyond_the_void_spec/BTV_AGENT_MEGA_PROMPT.md`
2. `docs/beyond_the_void_spec/STORY_BIBLE.md`
3. `docs/beyond_the_void_spec/CONTENT_AND_DATA_ARCHITECTURE.md`
4. `docs/beyond_the_void_spec/QA_AND_DEVICE_TEST_PLAN.md`
5. `docs/beyond_the_void_spec/OPENCODE_AND_MCP.md`
6. Every JSON example in `docs/beyond_the_void_spec/content_examples/`
7. `docs/beyond_the_void_spec/legacy-prototype-fixed.html`

If the master prompt cannot fit in one context read, inspect it in contiguous ranges and keep a checklist of the sections actually read. Do not report a complete review after reading only the first pages. The HTML file is a historical reference for the original Star Hopper concept, not the architecture to extend into the final native game.

## Audit, then implement

First report the actual versions and availability of Godot, Android SDK, Java/JDK, ADB, emulator/device, Git, and test tools. Inspect the existing code, create a safe checkpoint before major edits, and document any blockers. Use Godot 4.7.2 stable as the initial target unless compatibility evidence supports another stable version. Verify the installed version and official documentation rather than assuming.

Then move directly into implementation. Build a **working, tested vertical slice**, not merely a plan or architecture document. Prioritize portrait Android UX; responsive layouts for other devices; procedural exploration; planet landing; meaningful lifeforms and ecology; finite-stock trade and settlement economy; data-driven missions and dialogue; inventory, crafting, multitool modes, fictional defensive tools, ships and upgrades; base construction; persistent saves; and visually rich but scalable 2D lighting/material effects.

All dialogue, missions, items, species, recipes, ships, technologies, markets, and story expansions must be external versioned content with stable IDs. Implement schemas, references, content validation, save versions, migration, and idempotent rewards before expanding into large amounts of content. English is the default language for source content, UI, docs, and examples; keep localization support data-driven for future languages.

Use a staged workflow: implement one small feature group, add unit/integration tests, run them, fix failures, inspect the diff, then continue. Create a deterministic end-to-end scenario that starts a new save, lands on a planet, observes life, gathers and crafts an item, trades, progresses a quest, builds a functional module, changes a ship component, saves, restarts, and verifies the restored state. Test on the Android emulator/device through ADB when available. A desktop or headless run is not proof of Android validation.

Use MCP only where it creates a concrete benefit. Godot CLI/headless plus automated tests are the baseline. ADB/Android Emulator provides native-platform checks; `adb-mcp` may help operate a device if it is reviewed and compatible. Do not install unnecessary MCP servers, do not execute uninspected installation scripts, and do not expose local services or secrets.

After every stage, report: changed files, behavior actually implemented, commands actually run, test results, screenshot/log/report paths, APK path when built, known defects, blocked checks, and next concrete task. Never claim a feature works because its button exists or because the project opens.

**Start now:** audit the repository and toolchain, read the specification in full, implement the first vertical slice in the repository root, test it, fix it, and continue through the phases in the master prompt. The goal is a real, expandable Beyond the Void game, with Android as the number-one platform.
