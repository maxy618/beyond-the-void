# Exploration narratives: A Short Hike, Void Bastards, Dredge (additions to §5.1/§5.2)

Access date all sources: 2026-10-27. Companion files: `nms_narrative.md`, `longform_narrative.md`.

## Question
How do three additional shipped exploration games (a tiny authored open world, a
procedural roguelike campaign, an authored nautical horror loop) sustain story without
cutscene dumps, control scope, and decide what to proceduralize vs hand-author?

## Bottom line
- **A Short Hike** — movement-upgrade pacing is the content gate: the dev says a longer game
  would be hard "because you can just fly anywhere" (upgrade design problem, his explicit
  reason for not expanding). Dynamic layered music per area, texting-style dialogue with no
  silent protagonist as solo-dev survival strategies.
- **Void Bastards** — procedural *campaign*, authored *rooms*: "the game is very procedural
  with the exception of the level layouts… we built a large number of ships and save them out
  as completed levels." Level sizes were cut down or the loop degraded into a generic
  stage-based shooter.
- **Dredge** — one writer who can also program orchestrates atmosphere events timed to dialogue
  (sky darkens; a lightning strike lands on a specific line). Scope control credited to a
  quiet core loop: no direct combat, atmosphere without overt jumpscares. Lore started from
  one central plot object, not a full mythos.

## Evidence

| Claim | Source (direct URL) | Publisher / author | Date | Type | Verification |
|---|---|---|---|---|---|
| A Short Hike began Dec 2018 as a break-project from an RPG, funded as a Humble Original; dev cites Minit / Frog Detective as proof short focused games succeed; total playtime ~2 hours; dynamic area-progressive layered soundtrack by Mark Sparling; girlfriend/day playtester + friends contributed | https://gamepilgrim.com/2020/02/26/developer-interview-adam-robinson-yu | Game Pilgrim (interview with Adam Robinson-Yu) | 2020-02-26; retrieved 2026-10-27 | Developer interview (primary) | Verified |
| Writing method: texting-style dialogue (no capitalization, snippet sentences), no silent protagonist, improvisational first pass — explicitly chosen so a solo non-writer could ship dialogue; themes: self-doubt/anxiety; ending about parent relationships | same | same | same | Same | Verified |
| Not expanding to a long-form game: "I'd have to find a way to draw out the player's flying upgrades since it's difficult to design interesting levels when the player can just fly anywhere" | same | same | same | Same | Verified |
| GDC Vault talk exists: "Crafting A Tiny Open World: A Short Hike Postmortem"; search snippet describes "initial release came together within a 4-month deadline" | https://gdcvault.com/play/1026613/Independent-Games-Summit-Crafting-A | GDC Vault (Adam Robinson-Yu) | vault page down (maintenance) on 2026-10-27 | Developer video talk | **Vault page BLOCKED (maintenance); "4-month deadline" is search-snippet only — not verified **|
| Void Bastards original concept "Ghost Armada": present System Shock 2-style tactical situations "in a replayable, procedural format"; roguelike structure grew from there | https://gameworldobserver.com/2019/08/06/void-bastards | Game World Observer / Oleg Nesterenko (interview with Jonathan Chey, Blue Manchu) | 2019-08-06; retrieved 2026-10-27 | Developer interview (primary) | Verified |
| "The game is very procedural with the exception of the level layouts. Each ship is composed of a number of modules… the layout of these modules is not randomised (we built a large number of ships and save them out as completed levels)… it also adds to the gameplay as ships have designed layouts that make sense and those layouts can be learned over the course of the game." Explicit reason: stitching procedural 3D levels "is not trivial" | same | same | same | Same | Verified |
| Level sizes shrunk before ship: early levels "were larger than what we shipped with but we found that they just took too long to complete"; too long and "the game starts to feel a lot like a regular level based shooter" (loop = tactical run + strategic meta layer) | same | same | same | Same | Verified |
| Visual identity as deliberate indie strategy: "We want players to be able to look at a screenshot or a video of the game and identify it from other titles" | same | same | same | Same | Verified |
| Dredge's writer/programmer Joel Mason: dialogue sequences can orchestrate the sky darkening and a lighting strike timed to specific lines ("Wielding that ability as a programmer x writer feels very powerful"); expansion The Iron Rig cited as example | https://www.pointnthink.fr/en/joel-mason-writer-and-programmer-on-dredge | Point N Think (interview with Joel Mason, Black Salt Games) | page undated in extraction; retrieved 2026-10-27 | Developer interview (primary) | Verified |
| Dredge development: each area designed separately, months apart; free-flowing ideas + concentrated playtests producing "pages of (literally) hundreds of notes" | same | same | same | Same | Verified |
| Scope control: "fishing was one factor, but I also point at things like our lack of direct combat and our strong atmosphere without too many overt jumpscares" as "the gold standard of scope control"; lore "built up over time", started from one central plot point (The Collector's Book) | same | same | same | Same | Verified |
| Dredge own-site launch interview: "I always wanted people to have to put in a bit of work to piece things together" (story breakdowns exist because info is distributed) | https://www.blacksaltgames.com/dredge-launch-interview-with-development-team | Black Salt Games (own site) | — | Developer primary | **Fetch timed out (Timeout 25000 ms) on 2026-10-27; snippet only — not verified** (also surfaced via `free_search.search` result snippet) |

## Analysis
Three different answers to "what should be procedural": NMS path (see companion file)
proceduralizes addresses and injects typed authored POIs; Void Bastards proceduralizes the
*movement between* ship decks but keeps every deck authored — and explains that the opposite
(stitching) is the expensive part × adds learnable design; A Short Hike proceduralizes
nothing — it buys wonder with atypical scope (2 h) and a carefully restricted verb set.
Dredge buys connection evidence — encoded as a "look, don't fight" world with the *main
verdict left to the player*: Joel Mason "always wanted people to have to put in a bit of
work to piece things together" (own-site snippet — flagged).

Motion economics: two games explicitly control session length (Void Bastards ships smaller
levels; NMS's Void Bastards set a "feels almost mobile" loop). One author (A Short Hike)
refixed scope in the other direction: upgrade pacing is the *content* spend, and free flight
tears level-gating apart — the exact tradeoff for our jetpack/surface-flight blend.

## Contradictions and gaps
- No contradiction found between sources; they divide cleanly on "procedural vs authored".
- GDC Vault remains down (2nd session in a row) — any quantitative claims about the A Short
  Hike postmortem (4-month deadline, iteration counts) stay unverified.
- Black Salt Games' own site timed out (25 s); the launch interview quote about piecing
  story together is snippet-only.
- Dredge's randomized spawn/journal density: not evaluated here; no source opened.
- Void Bastards' story/quest generation internal rules (card/deck specifics) live in later
  paid-looking sources; not opened on this pass.

## Implications for Beyond the Void
*Evidence says:*
1. Author the *room*, generate the *address* (Void Bastards = NMS pattern, independently
   confirmed). Our planet mission stamp and POIs should be authored whole and placed, never
   stitched at runtime.
2. Session length is a designed quantity: Void Bastards shrunk levels to protect a loop-read
   as mobile ("scavange → meta"). Budget our planet excursion (walk to POI, act, return) to
   fit a session, and treat overshoot as a normal iteration target.
3. Movement upgrade pacing equals content pacing (A Short Hike): plan our jetpack/surface
   flight gate as a content gate from day one; every reachable area in each flight mode
   needs authored density, or the upgrade destroys level design.
4. A "look, don't fight" loop is scope control, not weakness (Dredge): our survey/observe/
   sample/repair loop with a Defensive Emitter matches a shipped 2023 success.
5. Dialogue that carries atmosphere beats (Dredge's timed lightning) is cheap and authored:
   our dialogue packs support `wait_for_event`/scene effects — use them, not bespoke scripts.
6. Restrict flight first (A Short Hike's expansion warning): biome/mission content must sit
   inside reachable verbs of the *current* ship.

*My judgement (not sourced):* BTV should pick Void Bastards' hybrid over NMS's full
proceduralism for surface map: stamp authored vignettes on generated terrain — it is the
documented way to get "authored feel" at non-trivial scale without a runtime stitcher.

## Sources
- https://gamepilgrim.com/2020/02/26/developer-interview-adam-robinson-yu — accessed 2026-10-27
- https://gdcvault.com/play/1026613/Independent-Games-Summit-Crafting-A — accessed 2026-10-27, **BLOCKED maintenance** (snippet corroborated via `free_search.search` result #1)
- https://gameworldobserver.com/2019/08/06/void-bastards — accessed 2026-10-27
- https://www.pointnthink.fr/en/joel-mason-writer-and-programmer-on-dredge — accessed 2026-10-27
- https://www.blacksaltgames.com/dredge-launch-interview-with-development-team — accessed 2026-10-27, **timeout, snippet only**
- https://www.dualshockers.com/void-bastards-interview-jonathan-chey-pc-xb1 — accessed 2026-10-27, **ERR_HTTP2_PROTOCOL_ERROR, unused**
- https://www.gamedeveloper.com/business/road-to-the-igf-adam-robinson-yu-s-i-a-short-hike-i- — accessed 2026-10-27, **Cloudflare verification wall, unused**

## Confidence
**High** for Void Bastards and A Short Hike design claims (developer interviews opened and
quoted verbatim). **Medium** for Dredge (one interview opened; second is snippet-only).
**Low** for GDC-postmortem quantitative facts (protected/unavailable).
