# Making procedural worlds feel authored (POI density, vignettes, spawn validation)

Access date all sources: 2026-10-27. Companion: `procedural_missions.md` (§5.3), `nms_narrative.md` (§5.1).

## Question
How do shipped games create POI density/spacing, place hand-authored vignettes inside
procedural coordinates, guarantee an opening beat and mission-critical sites, and avoid
copy-paste feel? Concrete numbers requested where evidence exists.

## Bottom line
- **Spacing/separation is a solved, parameterized problem (Minecraft):** every structure type
  has a grid `spacing` chunk size, a minimum `separation` padding, a salt, and an offset law
  (linear or triangular), with a biome search radius (112 blocks, 4×4 steps) and a
  ring-based search budget formula.
- **Spawn validation is also parameterized (Minecraft):** spawn selection evaluates 66 points
  on climate-noise/fitness rings up to 2048 blocks, refines on 16 circles / 862 points 32
  blocks apart, then falls to a chunk search for a non-waterlogged solid top block; JS/BE
  player placement box is 21×21 / 10×10 — and spawn-underwater-drowning still ships on
  Bedrock (documented failure mode).
- **Guaranteed counts + guaranteed contents (Terraria):** 1–6 floating islands per world by
  size, each with exactly one Skyware Chest holding one of 4 unique items (+1/3 sky mill);
  a generation read as an ordered list of named passes is shipped from source code.
- **Guaranteed contents inside procedurally tiled terrain (Noita):** biomes are Wang-tiled +
  "pixel scenes"; the Mines have documented guaranteed chest spawns, one of which is itself
  an authored pixel scene.
- **Room-grid authored chunks (Spelunky):** 16 rooms in a 4×4 grid, room types defined by
  guaranteed exits (~solution path first, then fill), all content authored per room.
- **Interactable budget per stage (Risk of Rain 2):** a "Scene Director" with an interactable
  credit pool (Abyssal Depths: 400 credits singleplayer; +50% per extra player), separate
  monster credits scaled by difficulty.
- **NMS planet identity** (typed compass POIs, one portal per planet) is verified
  structurally; numeric POI density per planet is NOT documented in openable sources —
  forum players describe "degrees of building density," unverified.

## Evidence

| Claim | Source (direct URL) | Publisher / author | Date | Type | Verification |
|---|---|---|---|---|---|
| Structure set data: grid spacing in chunks, `separation`: padding between placements; offset law `linear` or `triangular` (triangular = average of two randoms); biome search: radius 112 blocks, scan -X→+X, -Z→+Z in 4×4 squares, prefer `preferred_biomes`, else initial position; spread budget formula per ring N: `spread * (N² + 3N + 2) / 6`, spread ∈ [0,1023] | https://minecraft.wiki/w/Structure_set | Minecraft Wiki (documenting vanilla data) | page published 2026-10-19; retrieved 2026-10-27 | Structural wiki, data-backed | Verified |
| Vanilla examples (table header "Separation \| Spacing \| Salt \| Spread type"): abandoned_camp 8 / 37 (JE; BE 34, triangular BE), ancient_cities 8 / 24, buried_treasures 0 / 1 with "Probability of 1%" | same | same | same | Same | Verified (both rows read in-slice) |
| Spawn algorithm: evaluate 66 exact coordinates on rings of radius 0/512/1024/1536/2048 by distance to (0,0) + climate-sample fitness; then 16 circles ~32 blocks apart with 862 points; JE chunk-inspects a 5-chunk-square radius for a "topsolid non-waterlogged block"; player placement box 21×21 (JE) / 10×10 (BE); "sparatistec" climate-noise penalties can (and documented) fail: BE can spawn underwater and drown | https://minecraft.wiki/w/World_spawn | Minecraft Wiki | retrieved 2026-10-27 | Structural wiki | Verified; typo "discourages (but cannot fully prevent)" is how the page words the ocean rule |
| Terraria worldgen is an ordered pass list with internal names (Reset, Terrain, Skyblock, Dunes, Ocean Sand, Sand Patches, Tunnels, Mount Caves, Dirt Wall Backgrounds, Rocks In Dirt …); "dictated almost entirely by the World Seed"; generation cites source code | https://terraria.wiki.gg/wiki/World_generation | Official Terraria Wiki | page published 2024-06-02; retrieved 2026-10-27 | Structural wiki w/ source-code citation | Verified |
| Floating Islands: each world ≥1, up to 6 maximum in large worlds; each always has exactly one Skyware Chest with one of 4 unique items (Shiny Red Balloon / Starfury / Lucky Horseshoe / Celestial Magnet), 1/3 Sky Mill, 1/40 (2.5%) Fledgling Wings | https://terraria.wiki.gg/wiki/Floating_Island | Official Terraria Wiki | page published 2011-05-18; retrieved 2026-10-27 | Same | Verified |
| Spelunky level = 16 rooms in a 4×4 grid; 4 room types defined by guaranteed exits (type 1: left+right; type 2: left+right+bottom, +top if another type-2 above; type 3 as left descending solution path…); guaranteed solution path, remaining rooms type 0 | http://tinysubversions.com/spelunkyGen | Darius Kazemi, "Spelunky Generator Lessons" | site undated; retrieved 2026-10-27 | Reverse-engineering writeup (well-cited) | Verified (whole page logic read) |
| Noita biomes are "pseudorandomly generated via a combination of Wang tiles and Pixel scenes"; "all the guaranteed chest spawns in Mines. One of them being a pixel scene"; pixel scenes are added to the rendered biome | https://noita.fandom.com/wiki/World_generation | Noita Wiki (community) | page published 2026-07-29; retrieved 2026-10-27 | Community wiki | Verified (short page opened); wiki.gg mirror was Cloudflare-blocked |
| RoR2 Directors: Scene Director spawns all interactables during map setup from a per-environment credit budget; Abyssal Depths = 400 credits 1P, +50%/additional player (1000 @4P); monster credits scale by difficulty coefficient instead of player count; some maps grant extra fixed credits (e.g. +160) not scaled by players | https://riskofrain2.fandom.com/wiki/Directors | Risk of Rain 2 Wiki (community) | page published 2026-07-29; retrieved 2026-10-27 | Community wiki, mechanic-level | Verified |
| NMS: POIs are classed types (outposts/buildings, ancient structures, natural resources); compass icons by class; Signal Booster / Transmission Tower / Observatory scans permanently display markers until visited; mission-flagged markers persist while that mission is selected | https://nomanssky.fandom.com/wiki/Point_of_Interest | NMS Wiki | info-page update banner "as of 07 April 2026" (Remnant); retrieved 2026-10-27 | Community wiki | Verified |
| NMS: "Each planet has a single portal… located by using specific curiosities at Monoliths" (one guaranteed major landmark per planet) | same | same | same | Same | Verified |
| "Planets have actual degrees of building density … you'll not miss the buildings as they're everywhere" (high-density case) | https://www.reddit.com/r/NoMansSkyTheGame/comments/9ctsj7/question_about_buildingplaces_of_interest_spawns | r/NoMansSkyTheGame (forum) | thread undated via search; retrieved 2026-10-27 | Player forum | **Thread not opened (Reddit bot-wall on direct fetch pattern); snippet only — not verified** |

## Analysis
Two complementary layers are visible across games: **geometry-layer determinism**
(Minecraft's spacing/separation/salt grid + offset law; the same parameterization is what a
seeded 2D generator needs) and **content-layer budgets** (RoR2 credits; Terraria's
guaranteed island count + fixed unique-item set; Noita's guaranteed chests; Spelunky's
solution-path guarantee). NMS contributes the *legibility* piece: typed POIs + scan-driven
persistent markers, and the "exactly one portal per planet" rule is a clean example of a
guaranteed landmark.

Nobody ships a big "hand-stamped vignette inside a procedural address" at runtime without
parameters: Void Bastards authors full ship layouts as finished levels and complains that
stitching is hard; Noita/Minecraft/Terraria pre-author pieces (pixel scenes, structures,
islands) that slot into algorithmic coordinates. Spelunky's guarantee (solution-path room
types) is the same idea with a path check.

Spawn validation: Minecraft's three-stage funnel (coarse fitness → fine circles → chunk
search) plus a final non-waterlogged-solid placement rule is exactly our "slope check +
rejection sampling + safe radius + resource proximity" spec, implemented and shipped — but
note the documented failure (BE underwater spawn), meaning acceptance bars must be hard,
not probabilistic-preference-only.

## Contradictions and gaps
- No numeric NMS POI density exists in opened sources; only forum prose (snippet-only).
- Noita's precise placement RNG internals not read this pass (fandom page is thin;
  wiki.gg mirror Cloudflare-blocked). Wang tile + pixel scene wording is verified; the
  chest-queue mechanics beyond "guaranteed chest spawns" is unverified detail.
- DRG's hand-made cave-piece system: only a YouTube behind-the-scenes found (video out of
  scope); no openable article — recorded as an evidence gap for the "stamped chunk class".
- RoR2 numbers quote one environment (Abyssal Depths); the environment baselines differ by
  map and only one is quoted here.
- No source names concrete POI counts for Terraria pyramids/dungeons within slice-read
  length; only floating islands were carried as a guaranteed-count example.

## Implications for Beyond the Void
*Evidence says:*
1. **Adopt a two-parameter spacing model** for planet POIs (grid spacing in meters +
   minimum separation), plus a fixed per-planet-slot RNG salt — the Minecraft scheme is
   shipped vanilla data, not a hope.
2. **Budget interactables like RoR2:** per-planet interactable credit pool by biome tier
   (one number per planet, deterministic), spend-weighted by POI value; this gives bounded
   density instead of hand-tuned masks.
3. **Guarantee content, not just position (Terraria/Noita):** each planet draws its
   mission-critical stamp from an authored set; the stamp carries guaranteed contents
   (one chest-like objective, fixed unique promise), never depend on layer RNG.
4. **Path-first placement (Spelunky):** place the landing → mission POI → return path
   guaranteed, then fill the rest; type-0 filler ensures nothing else blocks the solution.
5. **Spawn validation as a funnel** (Minecraft): candidate beam fitness (slope, hazard,
   resource proximity) in coarse rings → fine circles ≥ N points → final check must PASS the
   acceptance bit (upright, non-fluid, inside bounds). A preference that can silently fail
   (Bedrock drowning spawns) is the documented failure to avoid.
6. **Guaranteed landmark legibility (NMS):** one primary landmark class per planet flagged
   by scan and marked permanently until visited.

*My judgement (not sourced):* BTV's "chunk-diff from biome + interactable credit pool +
authored stamp set" reproduces the six mechanics above with three rules and no runtime
stitcher — that is the right target for one short mission per planet.

## Sources
- https://minecraft.wiki/w/Structure_set — accessed 2026-10-27
- https://minecraft.wiki/w/World_spawn — accessed 2026-10-27
- https://terraria.wiki.gg/wiki/World_generation — accessed 2026-10-27
- https://terraria.wiki.gg/wiki/Floating_Island — accessed 2026-10-27
- http://tinysubversions.com/spelunkyGen — accessed 2026-10-27
- https://noita.fandom.com/wiki/World_generation — accessed 2026-10-27
- https://noita.wiki.gg/wiki/World_generation — accessed 2026-10-27, **BLOCKED (Cloudflare), unused**
- https://riskofrain2.fandom.com/wiki/Directors — accessed 2026-10-27
- https://nomanssky.fandom.com/wiki/Point_of_Interest — accessed 2026-10-27
- https://www.reddit.com/r/NoMansSkyTheGame/comments/9ctsj7/question_about_buildingplaces_of_interest_spawns — accessed 2026-10-27, **snippet only, Reddit not opened**
- Deep Rock Galactic video "Procedural Level Generation" (https://www.youtube.com/watch?v=cDcoMdHYdQg) — **VIDEO: out of scope, no transcript obtained; no text source opened**

## Confidence
**High** for Minecraft structure-set/spawn parameters and Terraria/Spelunky/RoR2 mechanics
(pages opened with numbers in-slice). **Medium** for Noita and NMS class system.
**Low** for NMS numeric POI density (no openable source) — explicitly not claimed.
