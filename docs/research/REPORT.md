# Beyond the Void — Research Report (authoritative)

Access date for all sources unless noted: **2026-10-27**. Tooling audit with per-tool
status and limits: `docs/research/tooling.md`. Per-topic deep files are linked from each
section; this REPORT is written to stand alone.

Status legend: ✅ researched · 🔶 partial · ⬜ not yet

| # | Section | Status |
|---|---|---|
| 1 | Narrative architecture for procedural exploration games | ✅ |
| 2 | Making procedural worlds feel authored (POI density, vignettes) | ✅ |
| 3 | Creature and combat encounter design | ✅ |
| 4 | Portrait mobile UI/UX for exploration games | ✅ |
| 5 | Godot 4.7 mobile feasibility for planned VFX | ⬜ |
| 6 | Risks, contradictions, explicit unknowns | ⬜ |

Deep files: `nms_narrative.md`, `longform_narrative.md`, `exploration_narratives.md`,
`worlds_authored.md`, `procedural_missions.md`, `tooling.md`, `agent_design.md`.

---

## 1. Narrative architecture for a procedural exploration game

**Question.** How do shipped exploration games sustain an authored throughline vs emergent
story, deliver endings, and hold a player-facing mystery without cutscene-heavy plot?

**Bottom line.**
1. **NMS** runs three concurrent narrative rails (Artemis/Atlas/Anomaly) but only one is
   onboarded in hour one; its opening is a fixed repair chain with one *guaranteed* storm —
   authored certainty, not randomness, makes the first beat land. Its ending was called a
   "dialogue-menu non-event" by named critics; the same surfaces were iterated back in NEXT
   patch notes. (`nms_narrative.md`)
2. **Outer Wilds** (designer's MFA thesis, read from the PDF): progression is knowledge-only,
   the world presents POIs that communicate *affordances* and it is "left up to the player"
   to chain them; writing rule: no pure-lore text, small mysteries rewarded *more often*.
   Climax was redesigned from "stop the end" to "understand why it ends".
   (`longform_narrative.md`)
3. **Obra Dinn / Sunless Sea** ship endings as *inspection of accumulated evidence*: a fixed
   countable ledger (60 fates) or a chosen Ambition (visible + hidden) with retirement — the
   ending must read as fair against what the player actually did. (`longform_narrative.md`)
4. **Void Bastards** (Jon Chey, primary interview): "procedural with the exception of the
   level layouts" — authored whole ships "saved out as completed levels" placed in a
   procedural campaign; level sizes shrank or the loop degraded into a generic shooter.
   **Dredge** (Joel Mason, primary interview): a writer who can also code programs
   atmosphere beats (timed lightning) into dialogue; scope controlled by no-combat +
   atmosphere-without-jumpscares; **A Short Hike**: don't scale it up — free flight
   destroys level gating ("difficult to design interesting levels when the player can just
   fly anywhere"). (`exploration_narratives.md`)

**Evidence (condensed).**

| Claim | Source (URL) | Author / publisher | Date | Type | Verification |
|---|---|---|---|---|---|
| NMS opening: crash/repair loop, guaranteed hazardous biome, one guaranteed storm beat, 28-step chain, no fail state; gifting items skips tutorials and blocks blueprints | https://nomanssky.fandom.com/wiki/Awakenings | NMS Wiki | as-of 2021, retrieved 2026-10-27 | Community wiki (structural) | Verified |
| NMS criticism "same things I was doing in the first hour" (50 h in); star choice "uninformed, therefore meaningless"; Atlas ending read as futile | https://www.ign.com/articles/2016/08/16/no-mans-sky-review · https://www.eurogamer.net/no-mans-sky-review | IGN / Eurogamer | 2016; retrieved 2026-10-27 | Named-outlet reviews | Verified |
| Outer Wilds thesis: curiosity = an answer to a question; POIs convey affordances; only memories/knowledge persist; no-pure-lore rule; climax redesigned to "understanding" | https://sbekumod.github.io/Assets/OWtesi.pdf | Alex Beachum (MFA thesis) | 2013; read 2026-10-27 | Designer primary | Verified (PDF pages read) |
| ME2 companion arcs unlock at one mid-game trigger affecting the finale; Citizen Sleeper episodes built on a "minimum viable version" authoring toolset (~1 month/episode) | https://masseffect.fandom.com/wiki/Loyalty · https://www.inverse.com/gaming/citizen-sleeper-gareth-martin-interview | ME Wiki / Inverse | retrieved 2026-10-27 | Secondary + developer interview | Verified |
| Void Bastards: ships authored whole; levels shrunk to protect the session loop; distinct visual identity as strategy | https://gameworldobserver.com/2019/08/06/void-bastards | GWO / Jon Chey | 2019-08-06; retrieved 2026-10-27 | Developer interview | Verified |
| Dredge: atmosphere triggered from dialogue scripting (sky darkens, lightning timed to a line); no direct combat + no overt jumpscares cited as scope control; plot object-first mythos | https://www.pointnthink.fr/en/joel-mason-writer-and-programmer-on-dredge | Point N Think / Joel Mason | undated page; retrieved 2026-10-27 | Developer interview | Verified |
| A Short Hike: texting-style dialogue, no silent protagonist; won't expand due to flight-gating design cost; dynamic layered score per area | https://gamepilgrim.com/2020/02/26/developer-interview-adam-robinson-yu | Game Pilgrim / Adam Robinson-Yu | 2020-02-26; retrieved 2026-10-27 | Developer interview | Verified |
| GDC "A Short Hike Postmortem" exists; "4-month deadline" claim from search snippet | https://gdcvault.com/play/1026613/Independent-Games-Summit-Crafting-A | GDC Vault | vault down (maintenance) 2026-10-27 | Developer talk | **BLOCKED; snippet only** |

**Analysis.** Two proven architectures trade off against cutscenes: NMS injects *typed POIs
with authored payloads* into procedural addresses and guides via one-selected-mission +
persistent markers + map dereference; Obra-Dinn/Outer-Wilds style games make *knowledge* the
progression currency and reserve the ending for inspecting what the player collected or
chose. Dredge and Void Bastards show the loop-level levers: atmosphere beats authored
inside system events, and authored rooms in a procedural campaign to keep "location design
that makes sense and can be learned".

**Contradictions and gaps.** GDC Vault pages down on both research sessions (maintenance);
Forbes Atlas-ending piece snippet-only; Reddit player sentiment bot-walled. NMS-era claims
(launch criticism) are 2016-dated; do not mix with 2026 Steam standing (Very Positive,
187,196 reviews on store page as accessed).

**Implications for Beyond the Void.** *Evidence says:* one primary mission rail at a time
(HUD marker + map dereference), no fail states, authored POI payloads in procedural
addresses, ending as inspection of an evidence board; small-mystery cadence; no pure-lore
dialogue. *My judgement:* our prologue+Act I subset should use the **evidence-board ending**
of the first planet mission and keep one guarantee-of-warmth beat (NMS's storm analog:
one guaranteed environmental pressure event) rather than three parallel rails.

**Sources.** See `nms_narrative.md`, `longform_narrative.md`, `exploration_narratives.md`
(sources tables include exact URLs + access dates; same access date 2026-10-27).

**Confidence.** High for quoted design interviews and thesis text; medium for wiki-derived
structural claims; low for GDC-vault-dependent numbers.

---

## 2. Making procedural worlds feel authored

**Question.** POI density/spacing, authored vignettes in procedural coordinates, guaranteed
opening beat, landmark readability, anti-copy-paste — with concrete numbers where shipped.

**Bottom line.**
1. **Minecraft** parameterizes POI distribution as (spacing grid, separation padding, salt,
   linear/triangular offset, biome search radius 112 blocks in 4×4 steps, ring-budget formula
   `spread·(N²+3N+2)/6`): vanilla ancient cities = separation 8 / spacing 24 chunks;
   abandoned camp 8 / 37; buried treasure 0 / 1 @1% chance. (`worlds_authored.md`)
2. **Minecraft spawn validation** is a funnel: 66 fitness-content points on climate-noise
   rings ≤2048 blocks → 862 points on 16 circles ~32 apart → chunk search for a
   non-waterlogged solid top → player box 21×21(10×10). Even so, Bedrock ships a documented
   failure (can spawn underwater and drown) — preference rules must not replace hard checks.
3. **Terraria** = ordered generation passes + guaranteed content counts (1–6 floating
   islands by world size; each always one chest with one of 4 fixed unique items).
4. **Noita** = Wang-tiled biomes + "pixel scenes" (authored chunks inside procedural
   terrain); Mines have documented guaranteed chest spawns. **Spelunky** = authored room
   types with guaranteed exits in a 4×4 grid guarantee a solution path first, filler later.
5. **Risk of Rain 2** budgets POIs with per-stage "interactable credits" (Abyssal Depths
   400 @1P, +50%/player) spent by a Scene Director; monster credits scale differently
   (difficulty coefficient). This is an interactive-budget POI economy.
6. **NMS** legibility layer: typed compass POIs, scans that permanently mark them, one
   guaranteed portal per planet. *Numeric planet POI density is not verifiable in openable
   sources* (forum claim snippet-only).

**Evidence (condensed).**

| Claim | Source (URL) | Publisher | Date | Type | Verification |
|---|---|---|---|---|---|
| Structure set fields + vanilla numbers (separation/spacing table) | https://minecraft.wiki/w/Structure_set | Minecraft Wiki | 2026-10-19 page | Data wiki | Verified |
| Spawn funnel numbers + underwater failure on Bedrock | https://minecraft.wiki/w/World_spawn | Minecraft Wiki | 2026 (retrieved) | Data wiki | Verified |
| Terraria passes + islands 1–6, fixed chest contents | https://terraria.wiki.gg/wiki/World_generation · /Floating_Island | Official Terraria Wiki | 2024-06-02 / 2011-05-18 | Structural wiki | Verified |
| Spelunky 4×4 room types, solution path | http://tinysubversions.com/spelunkyGen | Darius Kazemi | undated | Writeup | Verified |
| Noita Wang tiles + pixel scenes; guaranteed chest spawns in Mines | https://noita.fandom.com/wiki/World_generation | Noita Wiki | 2026-07-29 | Community wiki | Verified |
| RoR2 credit budgets per environment | https://riskofrain2.fandom.com/wiki/Directors | RoR2 Wiki | 2026-07-29 | Community wiki | Verified |
| NMS POI classes + portal-per-planet | https://nomanssky.fandom.com/wiki/Point_of_Interest | NMS Wiki | as-of 2026-04-07 | Community wiki | Verified |

**Analysis.** The industry's needle is a three-layer split: (a) deterministic geometry
(spacing/separation/salt), (b) content budgets (credits / guaranteed counts), (c) authored
chunks placed whole. Runtime "stitching" is the part developers publicly avoid
(Void Bastards), confirming the stamp-then-place model for a small team.

**Contradictions and gaps.** No text-verifiable source for Deep Rock Galactic's hand-made
cave chunks (only an official YouTube video — video out of scope). NMS numeric POI density
unknown. RoR2 baseline credited only for one environment in this pass.

**Implications for Beyond the Void.** *Evidence says:* seed → biome selection →
(spacing, separation) POI grid + interactable credit pool by biome tier → authored stamp set
draws 2–4 vignettes with fixed guaranteed contents → path-first guarantee (landing → POI →
return) → spawn funnel with hard acceptance bits (upright, in-bounds, non-fluid, resource
proximity, landmark in line of sight from spawn), never preference-only. *My judgement:*
one guaranteed landmark per planet flagged permanently by scan (NMS portal pattern) is the
cheapest readable identity device for portrait 2D.

**Sources.** `worlds_authored.md` (full table w/ access dates).

**Confidence.** High on parameterized claims (Minecraft/Terraria/RoR2); medium on NMS/Noita;
explicit gaps above.

---

## 3. Creature and combat encounter design

**Question.** Readable telegraphs, 2–4 enemy archetypes, risk without fail-state
punishment, touch controls — what shipped evidence and craft literature exist?

**Bottom line.**
1. **~4 archetypes per roster is shipped precedent**: Mike Stout's Skylanders archetypes
   "Near, Far, Swarmer, Heavy" (quoted by The Level Design Book), with a roster-matrix gap
   check against player abilities (Grunt/Squad/Leader/Tank/Swarm/Sniper). Melee-only is
   explicitly called "usually pretty boring"; ranged enemies make "environment matter".
2. **Telegraphing is a readability obligation**: unique silhouette readable at "~10+ meters";
   design details/animations that "telegraph enemy state, intent, and strengths/weaknesses";
   telegraphs = animation + SFX + VFX (+VO/haptics in 3D). Enemies exist to give specific
   player abilities screen-time.
3. **Risk without fail-state punishment ships in Dredge**: staged eye-dial panic 0–4,
   passive night gain (≈0→3 per night), disposal decay near lights/docks, and death =
   reload at last dock losing only post-anchor progress.
4. **Touch port practice (Dead Cells mobile)**: feasibility build FIRST; gesture schemes were
   prototyped and tested; final choice was **virtual buttons** + custom layouts; the UI was
   moved off the bottom edge (where hands are) so buttons own that zone. (`creature_combat.md`)

**Evidence (condensed).**

| Claim | Source (URL) | Author / publisher | Date | Type | Verification |
|---|---|---|---|---|---|
| Skylanders 4 archetypes + "Far Enemies… environment matters" | https://book.leveldesignbook.com/process/combat/enemy | Level Design Book citing Mike Stout | 2024-04-19 | Craft reference | Verified |
| Silhouette ~10 m; telegraph verbs; roster matrix | same | same | same | Same | Verified |
| Enemies emphasize player abilities; smoke-and-mirrors illusion | https://gdkeys.com/keys-to-rational-enemy-design | GD Keys / Nicolas Kraj | 2020-03-28 | Craft essay | Verified |
| Dredge panic stages 0–4 and dock-leniency | https://dredge.fandom.com/wiki/Panic · https://steamcommunity.com/app/1562430/discussions/0/6620895347253623016 | DREDGE Wiki / Steam thread | 2026-07-29 / 2023-04-04 | Community wiki + player thread | Verified |
| Dead Cells port: perf check first, buttons over gestures, UI off bottom | https://toucharcade.com/2019/05/07/dead-cells-mobile-blog-post | TouchArcade (reporting Playdigious port postmortem) | 2019-05-07 | Named outlet | Verified |
| Telegraph as animation+SFX+VFX mixture | https://www.gamedeveloper.com/design/enemy-attacks-and-telegraphing | Game Developer | undated | Article | **Snippet only — Cloudflare-blocked** |

**Analysis.** Three independent craft writers agree on few, role-distinct, intent-broadcasting
enemies; two shipped mobile/loop cases provide the "risk without deletion" pattern and the
touch-control settlement. Notably, no source supports a numeric windup-window standard —
timing values stay unsourced.

**Contradictions and gaps.** No numeric telegraph timing found anywhere openable; Dead
Cells' original porting postmortem + publisher feature list sit behind walls/timeouts
(snippet-only). Dredge panic rates beyond stage bounds are undocumented.

**Implications for Beyond the Void.** *Evidence says:* 2–4 role archetypes, one player-verb
exercise each; no attack without telegraph (silhouette + windup + SFX); staged
pressure meter + "reload at last landing zone" instead of death spirals; performance-first
port process; virtual buttons over gestures; keep the bottom edge for controls. *My
judgement:* apply the LDB "gap check" to our multitool modes (4 core telegrafts, plus
observation/repair modes that need non-combat pressure analogues).

**Sources.** `creature_combat.md`.

**Confidence.** High on archetype/telegraph, medium on death rules, medium-low on exact
touch layouts.

---

## 4. Portrait mobile UI/UX for exploration games

**Question.** HUD density, thumb reach, pause/settings, inventory access, readable
typography at ~720×1280 portrait — with primary-game and platform evidence.

**Bottom line.**
1. **Touch-size floors are platform mandates:** Apple HIG Buttons — hit region ≥ 44×44 pt
   (visionOS 60×60); Material — ≥ 48×48 dp ≈ 9 mm, 7–10 mm recommended, ≥ 8 dp between
   targets, 8 dp baseline grid (status bar 24 / toolbar 56 / list item 72).
2. **Thumb grip is measured and mixed:** Hoober street study (1,333 observations; 780 touch
   users): one-handed 49% / cradled 36% / two-handed 15%; right-thumb 67% of one-handed
   touches; grips switch every few seconds; reach zones are green/yellow/red.
   Hurff: bigger screens grow the unreachable "Ow" zone, not the comfortable zone.
3. **Engine-level safe area:** Godot `DisplayServer.get_display_safe_area()` /
   `get_display_cutouts()` exist with a documented support limit (cutouts: Android and
   macOS); Android Edge-to-Edge + iOS home-indicator guidance provided in docs.
4. **Shipped-port precedent (Dead Cells):** rough device-build feasibility FIRST; gesture
   schemes prototyped then replaced by virtual buttons; UI moved off the bottom edge and
   re-flowed. (`mobile_ui_ux.md`)

**Evidence (condensed).**

| Claim | Source (URL) | Publisher | Date | Type | Verification |
|---|---|---|---|---|---|
| 44×44 pt hit region | https://developer.apple.com/design/human-interface-guidelines/buttons | Apple HIG | accessed 2026-10-27 | Primary guidelines | Verified (rendered page text) |
| 48×48 dp, 9 mm, 8 dp grid | https://m1.material.io/layout/metrics-keylines.html · https://support.google.com/accessibility/android/answer/7101858?hl=en | Material / Google Help | accessed 2026-10-27 | Primary guidelines | Verified |
| Grip percentages + switching | https://web.archive.org/web/2020/https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php | Steven Hoober, UXmatters (via Wayback) | 2013 study; archived copy accessed 2026-10-27 | Field study | Verified (live site timed out ×3) |
| Thumb-zone heat map | https://www.scotthurff.com/posts/how-to-design-for-thumbs-in-the-era-of-huge-screens | Scott Hurff | 2014-09-18 | UX essay | Verified |
| Godot safe-area/cutout API + platform limits | https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_displayserver.rst | Godot docs repo | accessed 2026-10-27 | Engine docs | Verified (raw read) |
| Dead Cells port decisions | https://toucharcade.com/2019/05/07/dead-cells-mobile-blog-post | TouchArcade | 2019-05-07 | Named outlet | Verified |

**Analysis.** The mechanical contract is settled by platform docs; the exploration-specific
open question is typography (no source opened supports a "readable at 720×1280" point
size). HUD-density findings remain design judgement: they must not be presented as sourced.

**Contradictions and gaps.** 44 pt vs 48 dp is unit/platform difference, not a conflict.
Hoober is 2013-era — treat as floor. uxmatters live site inoperable; cited via Wayback.
Godot cutouts are not implemented for iOS (Android + macOS only, per docs).

**Implications for Beyond the Void.** *Evidence says:* 44 pt/48 dp hit floors; bottom band
owned by controls; safe-area queries instead of hardcoded margins; device-feasibility check
before UI polish. *My judgement:* one-line objective text should use our largest UI scale
setting by default, and every typography claim in our spec remains unverified until
measured on-device at 720×1280.

**Sources.** `mobile_ui_ux.md` (full table).

**Confidence.** High for touch sizes/safe-area/port decisions; medium for Hoober-era grip
stats; explicitly unsourced: game-specific typography minimums.

---
