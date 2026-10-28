# Creature and combat encounter design for small mobile action-exploration

Access date all sources: 2026-10-27.

## Question
What evidence exists for readable telegraphs, small enemy-archetype rosters (2–4), risk
without fail-state punishment, and touch controls in a small action-exploration game like
Beyond the Void's surface loop?

## Bottom line
- **Enemy rosters of ~4 archetypes are shipped precedent:** Skylanders' design used "4 main
  archetypes ('Near, Far, Swarmer, Heavy')" (designer Mike Stout, quoted by The Level Design
  Book), which adds the same roster-matrix method (Grunt/Leader/Tank/Swarm/Sniper) with a
  "gap check" against the player-ability list.
- **Readability is a stated design responsibility, with numbers:** unique silhouette
  discernible at "~10+ meters away"; animations/design details "**telegraph** enemy state,
  intent, and strengths/weaknesses." Melee-only is explicitly called boring — ranged matters
  because "environment matters" (Stout, via LDB).
- **Risk without fail-state punishment is a shipped loop:** Dredge stages pressure in an
  eye-dial HUD (0–4), with passive night gain (stage 0→3 over one night away from docks),
  decay near lights/docks, and death = reload at the last dock (docks are dense) losing only
  post-anchor progress — pressure to return, never a run-deletion spiral.
- **Touch ports prove virtual buttons over gestures and hand-clean screens:** Dead Cells
  mobile feasability was tested with a rough build FIRST; gesture schemes "were prototyped
  and tested" but "the old standby virtual buttons ended up being the most playable option";
  the mobile UI was moved *away from the bottom edge* (where hands sit) to free it for
  buttons.

## Evidence

| Claim | Source (direct URL) | Publisher / author | Date | Type | Verification |
|---|---|---|---|---|---|
| Skylanders archetypes: "designer Mike Stout talks about how the design team conceptualized 4 main archetypes ('Near, Far, Swarmer, Heavy')" + behaviors; Stout: "melee enemies by themselves are usually pretty boring… [ranged] 'Far Enemies… are very interesting because environment matters'" | https://book.leveldesignbook.com/process/combat/enemy | The Level Design Book (citing Mike Stout) | published 2024-04-19; retrieved 2026-10-27 | Design reference w/ designer quotes | Verified (page opened) |
| Readability spec in LDB: combat designer advocates "Unique **silhouette** so players can discern enemy type at mid-range (~10+ meters away)" and animations/details that "**telegraph** enemy state, intent, and strengths / weaknesses"; roster matrix Grunt/Squad Attack/Leader/Tank/Swarm/Sniper; "Only 1 Fast enemy? Maybe…" gap-analysis | same | same | same | Same | Verified |
| Enemy design rationale: each enemy should "[emphasize] a specific player's ability… make sure that all your abilities get the right screen-time"; combat = "smoke and mirrors" serving the player's experience (Truman-Show framing); fake doors must open etc. | https://gdkeys.com/keys-to-rational-enemy-design | GD Keys / Nicolas Kraj | published 2020-03-28; retrieved 2026-10-27 | Craft essay (named author) | Verified |
| Game Developer article on enemy attack telegraphing: telegraphs usually combine animation, SFX, voice-over, visual effects, sometimes force feedback (headline seen via search; page Cloudflare-blocked) | https://www.gamedeveloper.com/design/enemy-attacks-and-telegraphing | Game Developer | undated in search; accessed 2026-10-27 | Article | **Snippet only — page fetch blocked (Cloudflare "security verification")**. Same cite pattern as all gamedeveloper.com fetches this date. |
| Windup/anticipation phases "communicate attack type, timing, and direction" | https://salivity.github.io/game-development/article/designing-ai-attack-telegraphing-animations | salivity.github.io (no author/date shown) | undated; retrieved 2026-10-27 | Dev writeup | Verified as text; **credibility limited (no named author/date) — used as corroboration only** |
| Dredge panic: eye-dial HUD stages 0–4; passive gain at night away from docks/lights (0→3 per full night in absence of other effects); close-proximity chase creatures (Night Angler, Monster Ray, Serpent) raise panic; damaging hits add "moderate" panic; Miasma/Mind Sucker "massive"; loss: passive daytime decay, fast while docked; "Most panic manifestations can be avoided by docking" | https://dredge.fandom.com/wiki/Panic | DREDGE Wiki (community) | page fetched 2026-10-27 (cache) | Community wiki, mechanic-level | Verified (page opened, logic consistent) |
| Dredge death rule (player community): "If you die, you reload at your last save, aka the last time you docked. The game is extremely lenient on death due to how many docks exist, and you lose nothing for dying except whatever you did after undocking." | https://steamcommunity.com/app/1562430/discussions/0/6620895347253623016 | Steam Community (thread, 2023-04-04) | 2023-04-04; retrieved 2026-10-27 | Player community | Verified (thread opened) |
| Dead Cells mobile port: first step was a rough mobile build to check whether phones could run it at all; gesture schemes were prototyped and tested; virtual buttons won as "most playable option"; UI relocated off the bottom edge to avoid hands; many buttons squeezed onto a small screen | https://toucharcade.com/2019/05/07/dead-cells-mobile-blog-post | TouchArcade / Jared Nelson (reporting Laura Saada's Playdigious blog post) | 2019-05-07; retrieved 2026-10-27 | Named mobile-gaming outlet reporting a developer postmortem | Verified (page opened); underlying Gamasutra/Game Developer original is Cloudflare-blocked |
| Playdigious store copy: "Custom controls & More touch controls options available - Change the buttons' position and size to your liking, swipe to dodge… Revamped interface for mobile" | https://playdigious.com/games/dead-cells | Playdigious (publisher) | own site; fetch timed out 2026-10-27 | Publisher copy | **Snippet only — site fetch timed out (Timeout 25000 ms)** |

## Analysis
Telegraph + archetype literature converges from three independent design writers (Stout via
LDB; GDKeys' Nicolas Kraj; the salivity writeup) on: few role-distinct archetypes, each
tuned to exercise a player ability, delivered through silhouette + windup + intent. Death
avoidance literature is thinner but two shipped cases bracket the mobile reality: Dredge
(staged pressure + dock-save leniency) and Outer Wilds (knowledge persists through failure —
carried in `longform_narrative.md`). Touch evidence is centered on Dead Cells' port: not
gesture-first, not bottom-filled, and *performance feasibility verified before design*.

## Contradictions and gaps
- No numeric windup-window (e.g., ms-to-hit) source was openable; timing numbers remain
  unverified anywhere in this pass.
- GDKeys/pocketgamer deeper specifics (e.g., exact Dead Cells touch layouts: dual-zone
  virtual sticks, "buttons as needed") weren't accessible: pocketgamer timed out; the
  original Playdigious blog post is behind a Cloudflare wall.
- Dredge panic numbers (exact per-minute rates beyond "0→3 per night") are not documented on
  the wiki page read.
- No contradiction found between sources; all three telegraph writeups agree.

## Implications for Beyond the Void
*Evidence says:*
1. Ship 2–4 enemy archetypes as role classes (a melee-pressuring type, a ranged type, a
   swarming fast type, a heavy area-denial type) rather than 2–4 unique bosses — this is the
   Skylanders/LDB precedent. Each archetype must exercise one distinct player verb (e.g.,
   evade, repulse, out-of-range answer, interrupt).
2. Telegraph standard: distinct silhouette readable at play resolution, windup animation +
   SFX + state-GLOW flash before any strike; no attack without a readable intention
   broadcast.
3. Replace fail-state punishment with staged pressure + safe anchors: teleport-save-at-dock
   (Dredge) and persistent-knowledge loops (Outer Wilds) are the two proven patterns for
   exploration games. Our abduct-rescue "reload to last landing zone" preserves progress and
   removes run-deletion.
4. Mobile feasibility test before content: replicate the Dead Cells port order — rough
   performance build on target devices FIRST, then controls, then polish.
5. Prefer virtual buttons over multi-step gestures for the combat layer; reserve the bottom
   edge for controls and relocate status UI to the top or sides.

*My judgement (not sourced):* for BTV, a "telegraph-free" design would still need *intent
broadcasts* — both writeups incl. LDB treat telegraphs as a readability obligation, not an
optional polish. And the same LDB "gap check" should run against our multitool mode list.

## Sources
- https://book.leveldesignbook.com/process/combat/enemy — accessed 2026-10-27
- https://gdkeys.com/keys-to-rational-enemy-design — accessed 2026-10-27
- https://salivity.github.io/game-development/article/designing-ai-attack-telegraphing-animations — accessed 2026-10-27 (low-grade)
- https://dredge.fandom.com/wiki/Panic — accessed 2026-10-27
- https://steamcommunity.com/app/1562430/discussions/0/6620895347253623016 — accessed 2026-10-27
- https://toucharcade.com/2019/05/07/dead-cells-mobile-blog-post — accessed 2026-10-27
- https://www.gamedeveloper.com/design/enemy-attacks-and-telegraphing — accessed 2026-10-27, **BLOCKED (Cloudflare), snippet only**
- https://playdigious.com/games/dead-cells — accessed 2026-10-27, **timeout, snippet only**
- https://www.pocketgamer.com/next-level-gaming/playdigious-interview — accessed 2026-10-27, **timeout, unused**

## Confidence
**High** for archetype roster and telegraph/silhouette practice (three independent craft
sources, one with a named designer quote). **High** for Dredge panic stages (wiki opened).
**Medium** for death-leniency rule (Steam community thread, consistent with wiki sighting).
**Medium-low** for Dead Cells touch specifics (secondary report; primary Cloudflare-blocked).
