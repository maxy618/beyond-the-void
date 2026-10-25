# BEYOND THE VOID — OpenCode Development Pack

This directory is the project's **specification and reference library**, not the game project itself. Keep it under `docs/beyond_the_void_spec/` inside the main repository. OpenCode should work from the repository root and create the actual Godot project, game scenes, scripts, assets, content, tests, and build artifacts outside this specification folder.

## Package contents

- `OPENCODE_BOOTSTRAP_PROMPT.md` — the short English message to paste into the OpenCode chat after installing this pack. It explicitly separates the specification folder from the real game workspace.
- `BTV_AGENT_MEGA_PROMPT.md` — the controlling implementation brief. It includes architecture, platform priorities, gameplay systems, acceptance criteria, staged execution instructions, and the complete corrected Star Hopper HTML prototype as a historical reference.
- `STORY_BIBLE.md` — the canonical narrative intent, characters, campaign acts, side stories, endings, dialogue principles, and content-expansion rules.
- `CONTENT_AND_DATA_ARCHITECTURE.md` — recommended project organization, data schemas, stable IDs, modular content packs, save migration, simulation boundaries, and the contract between content and runtime code.
- `QA_AND_DEVICE_TEST_PLAN.md` — unit, integration, content-validation, deterministic-generation, long-session, visual, Android, and regression test requirements.
- `OPENCODE_AND_MCP.md` — a practical toolchain for OpenCode, Godot CLI, ADB, Android Emulator, test runners, and optional MCP integrations. MCP is an aid, not a substitute for tests.
- `content_examples/` — illustrative JSON records for dialogue, a quest, a species, an item, a ship, and a market. These examples are not automatically authoritative schemas; validate and improve them before using them in production.
- `legacy-prototype-fixed.html` — an independently runnable, corrected HTML Canvas prototype that preserves the original core idea and provides a reference for movement, star systems, scanning, and atmosphere.
- `opencode.jsonc.example` — a configuration example that must be checked against the installed OpenCode version before use.

## Recommended placement

Unzip or copy the contents to:

```text
BeyondTheVoid/
├── docs/
│   └── beyond_the_void_spec/
│       ├── README.md
│       ├── BTV_AGENT_MEGA_PROMPT.md
│       ├── STORY_BIBLE.md
│       ├── CONTENT_AND_DATA_ARCHITECTURE.md
│       ├── QA_AND_DEVICE_TEST_PLAN.md
│       ├── OPENCODE_AND_MCP.md
│       ├── content_examples/
│       └── legacy-prototype-fixed.html
├── project.godot                  # created in the actual project root
├── scenes/                        # actual game files
├── scripts/
├── content/
├── assets/
└── tests/
```

This is a target example, not a command to create every directory empty. The agent must inspect the repository first, preserve existing work, and introduce folders when they support a real implemented feature. The game must **not** be generated inside `docs/beyond_the_void_spec/`.

## How to start OpenCode

1. Place the specification folder at `docs/beyond_the_void_spec/` inside the actual repository.
2. Open OpenCode from the repository root, not from the documentation folder.
3. Send the complete text from `OPENCODE_BOOTSTRAP_PROMPT.md` in the OpenCode chat.
4. Require the agent to inspect the repository, Git status, Godot installation, Android toolchain, and available devices before making broad changes.
5. Have it implement and verify a playable vertical slice before expanding content. Require actual test output and honest device-test status in every progress report.

## Important principle

A large specification is not a finished game, and a successful project import is not proof that gameplay works. The agent must implement real mechanics, validate data, run automated tests, exercise complete gameplay paths, and distinguish emulator evidence from physical-device evidence. New story chapters and gameplay content must be addable as versioned data packs without rewriting the engine or invalidating old saves.
