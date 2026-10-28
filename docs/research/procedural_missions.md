# Procedural mission design and soft-lock prevention

## Question
How do shipped games generate short repeatable missions at scale — No Man's Sky mission
boards, Skyrim Radiant Story, Starfield mission boards, Elite Dangerous missions, Warframe
bounties, and academic quest generators — and what guarantees completability / avoids
soft-locks? How much authored structure is layered on top, and what failure modes are
documented? Deliverable: a minimum viable generator spec for one short mission per planet
in Beyond the Void.

## Bottom line
- The standard architecture across NMS, Skyrim, Elite and Warframe is the same five parts:
  a **board with a small number of slots** (NMS: exactly 5 procedurally generated missions
  per station board), **objective templates** (verb + target: courier/kill/cache-recover/
  liberate/sabotage), **target selection biased toward undiscovered locations** (UESP:
  Radiant "aims to send you to a location that you have not yet discovered"), **tiered
  rewards** (Elite: a choice of 3 reward packages; Warframe: rotating A/B/C pools 每 150
  minutes; NMS: units/nanites/blueprints with duplicates converted to units), and
  **standing/rank gating**.
- Soft-locks are avoided by **showing requirements before selection** (Elite shows the
  unfulfilled requirement right on the unselectable mission), **partial-progress retention**
  (Warframe: failing a later stage retains all previous-stage rewards), and keeping
  generated jobs strictly parallel to the main quest rather than gating it (UESP; Nesmith).
- The most valuable evidence is a designer admission: Bethesda's Bruce Nesmith ran an entire
  faction questline through Radiant Story and called the results "disastrous… ridiculous and
  tedious… giant rats in someone's basement" — concluding "Radiant Story is just a tool…
  not an end product."
- UESP's system documentation itself concedes Radiant **"cannot create large, complicated,
  or particularly interesting quests"** — it can only produce a near-infinite number of
  structurally simple ones.
- Academic planning-based generators (CONAN, IEEE/TCIAAG 2018) formalize quests as action
  sequences from world facts; their value for a tiny team is the data contract, not the
  planner.

## Evidence

| Claim | Source (direct URL) | Publisher / author | Date | Type | Verification |
|---|---|---|---|---|---|
| NMS station Mission Board: exactly **5 procedurally generated missions** at a time; slot 1 = system race, slots 2–4 = fixed guilds, slot 5 = high-rank (race or random guild); standing ranks replace low-rank offerings; rewards units/nanites/blueprints + reputation; duplicate blueprint → units instead; boards instanced per star system | https://nomanssky.fandom.com/wiki/Mission_Board | NMS Wiki (community) | page banner "as of 3 September 2024"; retrieved 2026-10-27 | Secondary wiki, structural | Verified |
| Skyrim Radiant: a "quest generator that creates quests from a series of components such as location, enemy type, and reward"; randomized components regenerate on each trigger; most radiant quests draw from "a set of about a dozen possible locations"; system "aims to send you to a location that you have not yet discovered"; "cannot create large, complicated, or particularly interesting quests" | https://en.uesp.net/wiki/Skyrim:Radiant | UESP (community reference) | page shows 2026-04-01 save; retrieved 2026-10-27 | Secondary wiki, structural | Verified |
| Radiant Story internals per lead designer: data attached to everything (NPC relationships, dungeon types, object functions), an event manager (death/item dropped/spell cast) starting quests (player kills NPC → related family member assigned "Avenger" role and attacks); an entire faction questline ("Companions") was attempted as fully procedural — "Early implementations … were disastrous … ridiculous and tedious … sent all the way across the map to kill giant rats in someone's basement"; resolution: "serious limitations on Radiant Story quests … Radiant Story is just a tool. It needs to be used properly in the service of making great game play. It is not an end product." | https://rpgamer.com/2022/03/bruce-nesmith-interview/ | RPGamer / Johnathan Stringer, interview with Bruce Nesmith | 2022-03-21; retrieved 2026-10-27 | Developer interview (primary) | Verified |
| Warframe bounties: board NPC (Konzu/Eudico/Mother/…); board "periodically generates a list"; 3–5 randomly located stages per bounty; tiered by difficulty; visible enemy level + standing + possible rewards before selection; **higher enemy level requires Mastery Rank**; per-stage rewards, **previous-stage rewards are retained even if a later stage fails**; each stage has an optional **bonus objective** for extra standing; reward pools A/B/C rotate every 150-minute cycle | https://wiki.warframe.com/w/Bounty | WARFRAME Wiki (official-hosted) | page shows "published 2026-09-30"; retrieved 2026-10-27 | Secondary wiki, structural | Verified |
| Elite Dangerous missions: faction representatives with portraits/allegiance; each mission shows **objectives, hazards/risks, full reward details**; unavailable missions **show the unfulfilled requirement** (reputation, cargo, cash); rewards are a choice of three packages (credits vs rep/commodities/materials/influence); ship destruction = mission data lost = failed in most cases | https://elite-dangerous.fandom.com/wiki/Mission_Board | Elite Dangerous Wiki (Fandom) | page shows "published 2026-10-23"; retrieved 2026-10-27 | Secondary wiki, structural | Verified |
| CONAN engine (procedural quest generation via planning): takes a world description as a set of facts (characters, locations, items), generates quest = sequence of actions toward a goal/reward; evaluated against structural analysis of commercial quests | https://arxiv.org/pdf/1808.06217 | Breault, Ouellet, Davies — IEEE Trans. Computational Intelligence and AI in Games (preprint on arXiv) | arXiv 1808.06217 (2018); retrieved 2026-10-27 | Academic primary | Verified (page 1 read from PDF) |
| Starfield's mishandled first impression & tutorial sprawl: the "walkout moment" replaced by "the grey-brown non-place of the planet Argos"; "you need a tutorial for mining, and … combat … planetary exploration … space combat … space navigation, and on and on"; frame "a game about exploration, without exploration" | https://www.eurogamer.net/starfield-review | Eurogamer (review) | retrieval 2026-10-27 (page undated in extraction; 2023 review) | Named-outlet review | Verified |
| "Procedural generation of branching quests for games" exists (Elsevier Entertainment Computing) | https://www.sciencedirect.com/science/article/pii/S1875952122000155 | Elsevier | — | Academic primary | **BLOCKED — CAPTCHA bot-wall on fetch (2026-10-27); title only via search** |

## Analysis
**One generator, five instantiations.** All five systems separate *content* from *selection*:
- *Content* = objective templates keyed to world facts (NMS guilds/missions list per station,
  Skyrim's per-quest location pools with occupant/hold filters, Warframe's per-landscape
  stage bundles, Elite's per-faction contract types).
- *Selection* = a small rotating offer panel with gating (standing in NMS, reputation in
  Elite, Mastery Rank in Warframe, player progress/location state in Skyrim).

**Completability and soft-lock avoidance, documented:**
1. **Pre-selection requirement display** (Elite) — an unaffordable mission is visibly locked
   with the reason shown; pickup time is never wasted on an unfeasible job.
2. **Materials guaranteed by the world, not by luck** — NMS stations only accept/complete
   board missions that reference content guaranteed in-system (kill N sentinels, scan fauna);
   the same instancing-per-system pattern keeps targets reachable. (Structural: Mission
   Board page.)
3. **Retained partial progress** (Warframe stages) converts failure into progress,
   the opposite of Elite's loss-on-death — both shippable models, different friction.
4. **Generated jobs must never gate the main quest** — UESP separates Radiant from
   main/faction key encounters; Nesmith's Companions experiment documents why.

**Authored layering on top of generation:** named board-givers with fixed personalities
(Konzu, Eudico), fixed slot patterns (NMS guild layout), one unique reward item per tier, and
— the Skyrim trick — *reactive* event-driven quests (avenger/drop/spell) that read as
authored drama while actually being generated.

**Documented failure modes:** (a) procedural-only questlines are "ridiculous and tedious"
(Nesmith); (b) simplicity ceiling, admitted in UESP's own text; (c) samey boards at low rank
(NMS's first slots are always low-rank race missions); (d) mission selection auto-switching
in NMS can silently move progress (Missions page); (e) Starfield's system sprawl — too many
tutorials diluting the loop (Eurogamer). None of these sources document "broken/unreachable
targets" as a shippable bug; that claim should stay out (gap noted below).

**Academic frame (CONAN).** For a tiny team, adopt CONAN's data contract — a world fact set
(characters, locations, items) + a plan/deck of action sequences — not a full planner. It
also suggests the eval trick: classify generated quests by *motivation* to prove variety.

## Contradictions and gaps
- **No clean primary source for Starfield's mission-board internals** was openable on this
  date: PCGamesN blocked (Cloudflare), Reddit bot-walled, Steam/forums community-only,
  screenrant/game8/theloadout are content farms excluded by the evidence rules. Starfield
  mission-board mechanics remain UNVERIFIED; only the Eurogamer review's framing is used.
- ScienceDirect (branching-quest paper) and UTwente (StoryWorld PDF) could not be opened
  (CAPTCHA; read timeouts ×2). ResearchGate returned an empty shell. Two arXiv papers did
  open; only CONAN is load-bearing here.
- The Elite mission-failure rule is summarised by a wiki; exact per-type exceptions (donation
  missions) were visible but not exhaustively read.
- No source here actually documents "radiant systems cause soft-locks" — the demonstrated
  failures are quality problems (tedium), not progression dead-ends. Treat soft-lock risk in
  our own design as architectural caution, not cited fact.

## Implications for Beyond the Void
*Evidence says:*
1. **Minimum viable generator for one short planet mission.** Data needed per planet seed:
   (a) planet fact set — biome, 8–12 POI types with authored payloads, hazard level, flora/
   terrain tags for target selection; (b) 4–6 objective templates (fetch relay part, map a
   region, survey a wreck, repair a cache, return to ship); (c) a reward table with 3
   choices styled after Elite (immediate resource vs unlock vs progress token); (d) a
   completion validator per template (proximity + interaction + item in inventory + return
   point). Validation checks the main quest too: every mission step's prerequisite must be
   obtainable with no player-guided items (the NMS lesson — gifted items skip steps and
   lock blueprints).
2. **Guaranteed reachability:** place the required target *at spawn selection time* within
   the validated landing plateau (as drafted in 5.4), exactly like Skyrim's
   "send you to a location you have not yet discovered" only inverted for a small map —
   bias toward 1 undiscovered POI at medium distance.
3. **Skill/gate display before commitment:** a disabled mission shows its unfulfilled
   requirement (Elite's verdict UI) — cheap and prevents frustration on mobile.
4. **Stage-partial rewards** (Warframe) fit a failed-stage mobile session: keepGetObjectives
   done before the player leaves still pay out.
5. **Keep generation vertical-slice-adjacent:** one authored beat per generated mission
   (an NPC voice line or a scripted reveal) is the documented difference between "tedious"
   (Nesmith) and "reads as authored" (Skyrim's avenger drama).
6. **Duplication guard:** if a template would repeat twice in a row on adjacent planets,
   swap it — NMS's duplicate-blueprint-to-units conversion shows the economy patch pattern.

*My judgement (not sourced):* for our 2D portrait game, 4 templates × 1 mission per planet ×
systematic auto-validation beats any richer planner; CONAN's "motivation classification" is
the cheapest per-version sanity test for our content validator.

## Sources
- https://nomanssky.fandom.com/wiki/Mission_Board — accessed 2026-10-27
- https://en.uesp.net/wiki/Skyrim:Radiant — accessed 2026-10-27
- https://rpgamer.com/2022/03/bruce-nesmith-interview/ — accessed 2026-10-27
- https://wiki.warframe.com/w/Bounty — accessed 2026-10-27
- https://elite-dangerous.fandom.com/wiki/Mission_Board — accessed 2026-10-27
- https://arxiv.org/pdf/1808.06217 — accessed 2026-10-27 (page 1)
- https://www.eurogamer.net/starfield-review — accessed 2026-10-27
- https://www.sciencedirect.com/science/article/pii/S1875952122000155 — accessed 2026-10-27 — **BLOCKED** (CAPTCHA)
- https://ris.utwente.nl/ws/files/307824333/3582437.3587181.pdf — accessed 2026-10-27 — **BLOCKED** (read_doc timeout ×2)
- https://www.researchgate.net/publication/359944464_Procedural_Generation_of_Branching_Quests_for_Games — accessed 2026-10-27 — **BLOCKED** (empty shell)

## Confidence
**High** for the five-game architecture and reward/gating specifics (each opened and quoted).
**High** for the failure-mode lesson (Nesmith quote is primary and directly on point).
**Medium** for the optional academic extension (one arXiv paper readable; Elsevier blocked).
**Low** on Starfield mission-board internals entirely — flagged as blocked, not claimed.
