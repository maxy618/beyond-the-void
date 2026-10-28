# Asset inventory — every visual element in Beyond the Void

Single source of truth for art. If an element is not listed here, it does not exist yet; if it is
listed without states, one PNG is correct.

Conventions that apply to every row:

- **View**: `side` = platformer surface view; `top` = looked at from directly above (space flight,
  orbit, map); `ui` = screen space.
- **Facing**: side-view creatures and ships are drawn facing **right**; the game mirrors them.
  Top-view ships are drawn with the nose **up** and must be mirror-symmetric across the vertical
  axis so they can rotate.
- **Frames**: `n` means `n` PNGs named `<name>_<state>_<i>.png`, `i` from 0.
- **Pivot**: grounded things rest on the bottom row of the canvas; flying things are centred.
- Palette ≤12 colours + 1 px outline, top-left light, pseudo-volume, no anti-aliasing.
- Every animation loops cleanly; every frame is inspected on its own at 768–1024 px preview.

Naming: `assets/sprites/<group>/<name>[_<state>][_<frame>].png`.
Sources: `assets/art_src/<group>/<name>.aseprite`.

---

## 1. Player — 46 frames

View: side. Canvas 24×30, feet on the bottom row.

| State | Frames | Dirs | Total |
|---|---|---|---|
| `idle` | 4 | down, up, left, right | 16 |
| `walk` | 4 | down, up, left, right | 16 |
| `jetpack` | 1 | down, up, left, right | 4 |
| `mine` | 1 | down, up, left, right | 4 |
| `combat` | 1 | down, up, left, right | 4 |
| `hurt` | 1 | down | 1 |
| `downed` | 1 | down | 1 |

`left`/`right` are a designed pair; do not blind-mirror the tool hand. Arms visibly thick from front
and back. No sideways backpack.

## 2. Player ship — two separate presentations

The ship is flown in space and seen from above; on a planet it is parked and seen from the side.
These are different drawings, never one rotated into the other.

**Flight, `top`, 64×64:**

| State | Frames | Notes |
|---|---|---|
| `<hull>_top` | 1 | nose up, engine nozzle at bottom, symmetric |
| `<hull>_top_thruster` | 2 | exhaust below the nozzle |
| `<hull>_top_bank` | 2 | optional roll hint for hard turns |

**Surface, `side`, 96×56:**

| State | Frames | Notes |
|---|---|---|
| `<hull>_landed` | 1 | gear/struts down, resting on the ground line |
| `<hull>_damaged` | 1 | torn opening with thick lit rim, missing panel, scorch |
| `<hull>_wreck` | 1 | nose dug in, broken spine, one wing up, debris on the ground |

## 3. Hulls and ship modules — 12 hulls

12 curated hulls, each with a genuinely different silhouette (a recolour is not a hull):
Seed Shuttle, Photon Courier, Cargo Barge, Fold-Scout, Ice Driller, Medical Ark, Reef Skimmer,
Solar Cutter, Gravity Tug, Quiet Archivist, Polarizer, Wanderhome.

Each hull also needs a **module set** so derelicts and traffic can be composed:

- cockpits ×6 silhouettes, cargo pods ×6, engine blocks ×6, wings/struts ×6, sensor arrays ×4.
- Each module in two states: intact, damaged.
- Modules are drawn to dock on a shared 8 px grid so compositions line up.

## 4. Curated fauna — 12 species, animated

Side view. States per species: `idle` 4, `walk`/`move` 4, `attack` 2 where hostile, `hurt` 1,
`die` 3. Passive species may skip `attack`.

| Species | Size | Role |
|---|---|---|
| `drone` | 20×14 | rogue survey drone, hovering, ranged |
| `grazer` | 24×20 | four-legged herbivore |
| `skitter` | 16×12 | small swarm crawler |
| `burrower` | 24×16 | ambush from the ground |
| `stalker` | 28×22 | predator quadruped |
| `hexapod` | 24×18 | six-legged grazer |
| `serpent` | 40×16 | sand serpent |
| `jelly` | 20×20 | floating drifter |
| `avian` | 24×16 | cliff flyer |
| `sporeling` | 16×16 | drifting spore creature |
| `manta` | 28×18 | wide-finned glider |
| `leviathan` | 96×40 | distant background giant, 4-frame glide only |

Nocturnal/alert variants are palette swaps in code, not new drawings.

## 5. Procedural part library — creatures

The ecology generator assembles bodies from authored parts. This is the scalable art system; without
it every procedural species would be a primitive blob.

`assets/art_src/creatures/parts/`, transparent, each part drawn in 3 size classes (S/M/L) where noted:

| Part family | Count | Notes |
|---|---|---|
| heads | 10 | quadruped, hexapod, serpent, avian, jelly, crawler variants |
| torsos | 8 | soft, shelled, segmented, floating |
| limbs | 8 | foreleg, hindleg, fin, wing, tendril, claw |
| wings/fins | 6 | membrane, feathered, ray |
| shells/armour | 6 | plate, spike, carapace |
| tails | 6 | whip, fan, stump |
| eyes/sensors | 8 | 1–4 eye clusters, glow variants |
| pattern stamps | 12 | stripes, spots, bands, speckle, glow lines |
| fronds/leaves | 10 | for flora genomes |
| bulbs/glow organs | 6 | |
| stalks/trunks | 6 | |
| roots/mats | 6 | |

Mount sockets and size classes are defined in `docs/art_production_brief.md` → creature parts.
Every part must compose without breaking the silhouette at 3× gameplay scale.

## 6. Curated flora — 12 species, 2 states + sway

| Species | Size | States |
|---|---|---|
| `kelp` | 16×32 | `sway` 4, `cut` 1 |
| `fern` | 20×20 | `sway` 4, `cut` 1 |
| `bell` | 16×20 | `sway` 4, `cut` 1 |
| `moss` | 16×10 | static, `cut` 1 |
| `saltreed` | 16×36 | `sway` 4, `cut` 1 |
| `bulb` | 16×18 | `sway` 4, `cut` 1 |
| `cactus` | 18×28 | static, `cut` 1 |
| `fungus` | 20×16 | `sway` 4, `cut` 1 |
| `vine` | 16×40 | `sway` 4, `cut` 1 |
| `crystal_bloom` | 20×24 | `pulse` 4, `cut` 1 |
| `canopy_tree` | 64×96 | `sway` 4, `cut` 1 |
| `mat` | 32×12 | `sway` 4, `cut` 1 |

All sway frames move in one wind direction and share the same root pixel.

## 7. Minerals and scatter — 6

| Name | Size | States |
|---|---|---|
| `rock` | 16×10 | static |
| `boulder` | 24×13 | static, mossy variant |
| `crystal` | 16×24 | `pulse` 4, `mined` 1 |
| `ore_vein` | 24×16 | `intact`, `mined` |
| `salt_deposit` | 24×12 | `intact`, `mined` |
| `fossil` | 20×12 | static |

## 8. Structures — tilesets, not single props

Procedural ruins are built from tilesets. Four cultures × four decay stages:

- Cultures: settlement, research, industrial, shrine.
- Decay: intact, weathered, collapsed, overgrown.
- Per culture: floor tiles ×6, wall tiles ×8, doorway ×2, window ×2, roof edge ×4, stairs ×2,
  prop cluster ×4.

Hand-placed structures (2 states each where noted):

| Asset | Size | States |
|---|---|---|
| `pod` | 40×40 | `closed`, `open` |
| `workbench` | 40×24 | `idle`, `active` 2 |
| `market_stall` | 64×40 | `open`, `closed` |
| `relay` | 24×48 | 3 damage states + `beacon` 4 |
| `dish` | 20×12 | `rotate` 4 |
| `mast` | 24×48 | static + `beacon` 4 |
| `canopy` | 48×24 | static, code-driven ripple |
| `counter` | 40×20 | static |
| `plate` | 16×12 | static |
| `engine` | 24×18 | static + `heat` 2 |
| `wreckage` | 96×56 | static hero wreck |
| `habitat` | 64×48 | `intact`, `damaged` |
| `storage` | 48×40 | `intact`, `damaged` |
| `refinery` | 80×56 | `intact`, `damaged` |
| `beacon_tower` | 40×72 | `intact`, `damaged` |

## 9. Ground, water, biome edges

- Ground: 4 biomes (`mist`, `crystal`, `shore`, `default`) × 4 seamless variants × 128×128 = 16.
- Water: 4 frames × 128×128, seamless, transparent, foam and ripple travel.
- Biome edge/transition tiles: 4 sets × 3 tiles (left edge, right edge, corner) = 12.
- Cliff/slope faces: 4 × 3 tiles.
- Decals: 8 (cracks, scorch, moss patch, pebbles, root, spore ring, salt stain, footprint).

## 10. Space and orbit — top view

| Asset | Size | States |
|---|---|---|
| planet disc set | 256×256 | 5 curated planets × (day, night lights, cloud layer, atmosphere ring) |
| gas giant bands | 256×256 | 3 variants, 4-frame rotation |
| rocky planet surface patches | 128×128 | 6 |
| black hole | 384×384 | 8-frame accretion swirl + lensing ring |
| starfield tiles | 128×128 | 4 parallax layers, seamless |
| nebula | 512×256 | 4 variants, soft but non-AA pixel clusters |
| asteroid | 32×32 | 4 silhouettes × 2 states (intact, cracked) |
| station | 96×96 | 3 cultures × (idle, docked lights 4) |
| jump gate | 96×96 | `idle` 4, `active` 4 |
| derelict ship | uses hull + module composition | — |
| space debris | 16×16 | 4 |

## 11. Characters and portraits — UI view

| Asset | Size | States |
|---|---|---|
| Ari portrait | 96×96 | neutral, speaking, hurt, tired |
| Sol portrait (AI) | 96×96 | idle waveform 4, speaking 4, alert 4 |
| Kasa portrait | 96×96 | neutral, smiling, worried |
| Cass Ember portrait | 96×96 | neutral, guarded, tired |
| generic NPC portraits | 96×96 | 4 cultures × 2 moods |
| NPC standing sprites | 24×30 | 4 dirs × idle 4; reuse player rig proportions |
| NPC walk | 24×30 | 4 dirs × 4 |

## 12. UI — screen space

- **HUD frames:** hull bar, shield bar, energy bar, oxygen, fuel, temperature, compass, minimap
  frame, objective banner, interaction prompt, damage vignette (9-slice where applicable).
- **Icons 16×16 and 24×24:** 6 minerals, 12 flora harvests, 8 fauna samples, 12 ship modules,
  12 technologies, 10 status effects, 8 damage types, 6 currencies/tokens, 6 map markers,
  8 journal categories, 6 crafting categories, 4 save slots.
- **Touch controls:** joystick base + knob (48×48), fire button, jetpack button, mine button,
  interact button, menu button — normal/pressed/disabled states.
- **Reticle:** 16×16, 4 states (idle, hostile, mining, locked).
- **Panels and chrome:** window frame 9-slice, button normal/hover/pressed/disabled, tab
  active/inactive, slider track/fill/knob, toggle on/off, scrollbar, tooltip, modal scrim.
- **Screens needing layout art:** main menu, settings, inventory, storage, crafting, trading,
  ship loadout, multitool wheel, dialogue, journal, field catalogue, system map, save/load,
  content overview. Each needs empty/loading/error/disabled states.

## 13. VFX sprites

| Asset | Frames | Notes |
|---|---|---|
| `muzzle_flash` | 3 | player weapon |
| `bolt_player` | 2 | projectile |
| `bolt_hostile` | 2 | projectile |
| `impact_spark` | 4 | |
| `explosion` | 6 | |
| `smoke_puff` | 6 | |
| `jetpack_flame` | 4 | |
| `mining_beam` | 3 | |
| `scan_pulse` | 5 | |
| `dust_mote` | 4 | |
| `spore` | 4 | |
| `leaf` | 4 | |
| `rain_streak` | 2 | |
| `sand_grain` | 2 | |
| `ash_flake` | 2 | |
| `water_splash` | 4 | |
| `warp_streak` | 3 | |

## 14. Weather overlays

Sandstorm, rain, mist, ash, snow — shader/particle driven, but each needs authored grain and haze
textures at 128×128, seamless, plus a horizon haze gradient strip.

## 15. Ownership map

| Group | Owns | Session |
|---|---|---|
| Player | §1 | `ses_e80f49a7fffeyrcrU0y5us1lZN` |
| Ground/water | §9 | `ses_e80f95bbfffeMmArMdV8rzZbDq` |
| Structures | §8 (hand-placed only) | `ses_e80f95ba3ffe443v7jY63FEgFL` |
| Props/minerals | §7, `reticle` | `ses_e80f7e947ffez9CH5kE1v7pSqv` |
| Fauna | §4 | `ses_e80f49a7dffeDk6QKWFhrZoSJE` |
| Flora | §6 | `ses_e80f49a7bffeh5kS0b47kTebj9` |
| Ships | §2, §3 | `ses_e80efc352ffeCcTFahyAtke99C` |
| Space | §10 | to launch |
| UI/icons/portraits | §11, §12 | to launch |
| Part libraries + tilesets | §5, §8 tilesets | to launch |
| VFX | §13, §14 | to launch after VFX code |

## 16. Acceptance

An asset is accepted only when:

1. Its `.aseprite` source and 1× PNG exist at the contracted paths.
2. Every state and frame in this document exists; a missing state means not delivered.
3. The artist `read` the exported PNG at 768–1024 px after the last change.
4. The standard transforms were checked: full view, 3× gameplay scale on a biome background,
   16× detail crop, light and dark background, tiling where relevant.
5. The primary agent `read` the same preview and found no named defect.

Anything below this is labelled a stylized prototype.
