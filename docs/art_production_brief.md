# Beyond the Void — Art Production Brief (Mimo)

**`docs/asset_inventory.md` is the authoritative list of every visual element, state, view and frame
count.** This brief defines the quality bar and the working method; the inventory defines what must
exist. If they disagree, the inventory wins on scope and this brief wins on quality.

This file is the binding brief for the artist. It is deliberately detailed: the game's visual
quality is the deliverable, not a checkbox. Read it fully before drawing, and re-read it before
every delivery.

## 0. Non-negotiables

- Rebuild all art from zero. `assets/` is empty; no old art is to be reused.
- Work only in `assets/art_src/` (editable sources) and `assets/sprites/` (exported PNGs).
- Use the Aseprite MCP tools. Do not edit gameplay code or `scripts/world/pixel_sprites.gd`.
- **Vision first.** Open and inspect every image at full resolution before judging it, after every
  change, and again after every fix. No batch approval. Hero assets need at least 3 inspected
  passes; every animation frame is inspected individually.
- **Video review.** Mimo can watch video. Export every animation as a looping GIF/MP4 at 2× and 3×,
  watch it end to end, and judge loop seam, timing, foot sliding, arcs, weight, anticipation,
  follow-through, secondary motion, and flicker that only appears between frames. If video cannot
  be ingested, say `BLOCKED` — never pretend.
- Iterate until it is genuinely good. One pass is never enough. In every report name the exact
  files/videos inspected, what you saw, what is still wrong, and what you are fixing next.
- The primary agent integrates; it does not draw sprites. Report defects you dislike even if the
  code works.

## 1. Look and feel

- Target: Terraria / Soul Knight density and readability, but sci-fi isolation and wonder.
- Portrait mobile first. The player must read at 360×640 internal resolution and at 720×1280.
- Neutral mid-value palettes so biome/climate tinting works. Avoid pure black fills, neon overload,
  and one-hue palettes.
- Light from top-left. 1 px outline in the darkest palette step. No anti-aliasing. No stray pixels.
- Maximum 12 colours + outline per asset. Reuse a coherent material palette across related assets.
- Dense, authored clusters. Never build a finished silhouette from circles, polygons or primitive
  stand-ins.
- Every living thing has a living idle: breathing, sway, weight shift, secondary motion. Never a
  three-frame loop that just bobs.

## 2. Player — hero asset, highest priority

Folder: `assets/sprites/player/`. Frame box 24×30, transparent, feet on the bottom row, centred.

Directions: `down`, `up`, `left`, `right`.
Poses/frames:
- `idle_0.png` … `idle_3.png` — breathing loop, weight shift, helmet/antenna sway.
- `walk_0.png` … `walk_3.png` — contact, down, passing, up; arms swing opposite legs.
- `jetpack_0.png` — body lifted, legs tucked, flame anchor visible.
- `mine_0.png` — tool braced, recoil-ready stance.
- `combat_0.png` — weapon braced, shoulders squared.

Requirements:
- **Arms must be visibly thicker from the front and from the back.** The suit reads as a sealed
  exploration suit with heavy forearms/gauntlets, not sticks.
- No sideways backpack. The pack sits on the back, readable in side/up views, never as a box
  hanging off one side.
- Down and up views must be distinguishable by visor, chest rig, pack and arm silhouette — not
  only by colour.
- Left/right are a designed pair; do not mirror blindly if it breaks the tool hand.
- Helmet light, chest seams, knee/elbow pads, boot soles: small readable details at 3× zoom.

## 3. Creatures and props

Folder: `assets/sprites/props/`. One PNG per name, transparent, feet/base at the bottom.

| Name | Approx. size | Notes |
|---|---|---|
| `drone` | 20×14 | rogue survey drone; red sensor, hovering, readable at small size |
| `grazer` | 24×20 | passive herbivore; soft body, four legs, living idle |
| `manta` | 28×18 | drifting flyer; wide fins, trailing tendrils |
| `rock` | 16×10 | small scatter rock |
| `boulder` | 24×13 | larger, mossy |
| `crystal` | 16×24 | cyan/amber facets, glow core |
| `kelp` | 16×32 | swaying, translucent fronds |
| `fern` | 20×20 | layered fronds, warm green |
| `bell` | 16×20 | bell-shaped flora, soft glow |
| `moss` | 16×10 | ground cluster |
| `reticle` | 16×16 | thin cyan/amber targeting reticle |
| `plate` | 16×12 | hull plate with seams and rivets |
| `mast` | 24×48 | relay mast, antenna details |
| `dish` | 20×12 | relay dish, readable profile |
| `canopy` | 48×24 | market canopy, warm fabric |
| `counter` | 40×20 | market/workbench counter, worn metal/wood |
| `workbench` | 40×24 | **crafting station**: heavy bench, tool rack, clamps, worn top |
| `engine` | 24×18 | ship engine block, nozzle and heat stains |
| `wreck` | 96×56 | **hero wreck**: crashed ship, broken hull, exposed ribs, no orange-plate look |
| `pod` | 40×40 | entry pod, heat-scarred, window and thruster |

`wreck` and `pod` are new; the code will be wired to them. Until then the loader falls back.

## 4. Ground and water

Folder: `assets/sprites/ground/`. 128×128, seamless in both axes, no visible tile grid.

- `mist_0.png` … `mist_3.png` — temperate green/teal ground, fine grass and soil, no speckle carpet.
- `crystal_0.png` … `crystal_3.png` — fractured slate with crystal shards.
- `shore_0.png` … `shore_3.png` — wet sand/pebble, transitional.
- `default_0.png` … `default_3.png` — neutral fallback.

The world selects four variants (`% 4`), so deliver 0–3 for every biome.

Keep values mid-range and desaturated; the game tints biomes. Variants must differ in structure,
not only hue. Avoid the dark vertical band caused by mismatched chunk edges: every variant must
tile with every other variant without a seam.

Folder: `assets/sprites/water/`.
- `0.png`, `1.png` — 128×128 seamless, transparent water with foam/edge highlights; two animation
  phases that loop cleanly.

## 5. FX

- `assets/sprites/fx/shadow.png` — 24×10 soft elliptical contact shadow, transparent.
- Additional FX are procedural in code unless requested.

## 6. Animation and delivery

- Sprite sheets are not used; deliver individual frames with the exact names above.
- Every animation loops cleanly. Walk cycles must not slide: contact foot stays planted relative to
  the body during the contact phase.
- Idle loops are 4 frames minimum and include at least two kinds of motion (breath + sway, etc.).
- Deliver player first, then drone/grazer/manta, then wreck/pod/props, then ground/water, then flora.
- Export continuously; do not wait for a perfect full set. Tell the integrator what is ready.

### 6.1 State and animation matrix — every asset, exhaustive

Nothing in the game is a single frozen picture unless it is listed as static here.

**Player** — 24×30, 4 directions (`down`, `up`, `left`, `right`):

| State | Frames | Notes |
|---|---|---|
| `idle_0..3` | 4 per direction = 16 | breath + weight shift + antenna sway |
| `walk_0..3` | 4 per direction = 16 | contact, down, passing, up |
| `jetpack_0` | 1 per direction = 4 | legs tucked, flame anchor |
| `mine_0` | 1 per direction = 4 | tool braced, recoil |
| `combat_0` | 1 per direction = 4 | weapon braced |
| `hurt_0` | 1 | recoil, head back, flash-ready |
| `downed_0` | 1 | collapsed on the ground line |

Total 46 PNGs. Left/right are a designed pair; do not blind-mirror the tool hand.

**Creatures** — one folder per creature, `assets/sprites/props/<name>_<state>_<frame>.png`:

| Creature | States | Frames | Notes |
|---|---|---|---|
| `drone` | `idle` 4, `attack` 2, `die` 3 | 9 | hover bob, sensor pulse, rotor vibration; `attack` = sensor flare + recoil; `die` = tilt, spark, fall |
| `grazer` | `idle` 4, `walk` 4, `hurt` 1, `die` 3 | 12 | breath, ear/tail; four-leg walk; left/right via horizontal flip |
| `manta` | `glide` 4, `bank` 2, `die` 3 | 9 | wing beat, tendril trail; `bank` = roll for turning |

No mirrored duplicate files: side-facing creatures are drawn facing right, the game flips them.

**Flora** — animated, 4-frame loops, honouring one wind/current direction:

| Asset | Frames | Notes |
|---|---|---|
| `kelp` | 4 | S-curve sway, blades lag behind the stalk |
| `fern` | 4 | frond tips flutter, base anchored |
| `bell` | 4 | soft glow pulse, stem sway |
| `moss` | static | ground cluster |

**Structures and props** — static unless listed:

| Asset | States |
|---|---|
| `workbench` | static + `workbench_active` 2 frames (tool glow / clamp open) |
| `pod` | `pod_closed`, `pod_open` (hatch up, interior dark) |
| `dish` | `dish_0..3` slow rotation loop |
| `mast` | static + `mast_beacon_0..3` light pulse |
| `canopy` | static; fabric ripple is code-driven vertex sway, not frames |
| `counter`, `plate`, `engine` | static |
| `rock`, `boulder`, `crystal`, `reticle` | static |

**Ships** — 12 hulls. A ship has two completely different presentations; they are not interchangeable:

*Flight (space / atmosphere), 64×64, top-down:*

- `<hull>_top.png` — seen from directly above, nose pointing UP, engine nozzle at the bottom edge. This is the sprite used in space cruise, combat and orbit. Never reuse the side view here.
- The hull must be mirror-symmetric across the vertical axis so the game can rotate it in flight without the silhouette falling apart.
- Cockpit glass, hull plate seams, wing/strut layout and engine glow must read from above only — a side profile rotated 90° is not a top view.
- `<hull>_top_thruster_0..1.png` — 2-frame exhaust below the nozzle.

*Surface (landed, damaged, wrecked), 96×56, side view:*

- `<hull>_landed.png`, `<hull>_damaged.png`, `<hull>_wreck.png`.
- These sit on the ground line at a landing pad or crash site; they are never shown flying.

Known limitation to state in the report: code rotation of a single top view is a prototype measure. If it reads badly at gameplay scale, the upgrade is 8 pre-drawn directions per hull — say so, do not hide it.

**Ground / water:**

- 4 seamless variants per biome (`mist`, `crystal`, `shore`, `default`) = 16 tiles, 128×128.
- Water `0..3` = 4-frame loop (not 2): surface shift, foam break, ripple travel.
- `fx/shadow.png` static 24×10.

**Missing state = not finished.** A creature with one PNG is a placeholder, not a delivered asset.

## 7. Visual effects targets (code, not drawn assets)

These are integration targets for the primary agent; the artist reviews the result:

- Bloom / glow on crystals, engines, visors and UI accents; configurable Low/Medium/High/Ultra.
- Light shafts (god rays) through canopy and dust; configurable.
- Wet/glass/crystal reflections: specular glints, mirror-like puddles, water reflections; not fake
  ray tracing. Configurable.
- Water: animated surface, foam, refraction, depth tint; quality-scaled.
- Motion blur: subtle, optional, off by default on mobile; disabled by reduced motion.
- Particles: dust, spores, sparks, rain, sandstorm; density scaled by quality.
- All of the above exposed in Settings and persisted; every preset must visibly differ.

## 8. Report format

Every delivery report must list:
1. Exact files/images/videos inspected (paths).
2. What was seen, including defects.
3. What changed since the previous pass.
4. What is still wrong or `BLOCKED`.
5. What is next.

No claim of "final" without the inspected passes and video review.

## Vision and test consultation (permanent)
The primary agent ALWAYS consults the designated visual QA artist on every visual change and every visual test. It hands over real gameplay captures and animation clips; an unreviewed screenshot is not evidence. The artist's verdict is binding: exact file or capture, named defect, required fix. The primary fixes and re-submits.
Parallel artist sessions are allowed only on completely disjoint asset sets with declared ownership; never let two sessions edit the same file. The primary waits for all sessions and integrates their work.