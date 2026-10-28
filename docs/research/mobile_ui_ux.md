# Portrait mobile UI/UX for exploration games (HUD density, thumbs, pause, typography)

Access date all sources: 2026-10-27.

## Question
What primary evidence defines touch sizes, thumb reach, HUD density, pause/settings
patterns, inventory access, and method readability at ~720×1280 portrait in mobile games?

## Bottom line
- **Touch targets: 44×44 pt (Apple HIG) / ≥48×48 dp (~9 mm; 7–10 mm recommended spacing, 8 dp
  between targets – Material).** Both primary sources opened directly.
- **Thumb reach is real, measured, and grip-switch heavy:** Hoober's street study (1,333
  observations across two months ending 2013-01-08, 780 touch users): one-handed 49%,
  cradled 36%, two-handed 15%; in one-handed use the right thumb touched the screen 67%
  (left 33%); users switch grips seconds apart; reach follows a green/yellow/red zone model.
  Hurff (2014) formalizes the "Thumb Zone" heat map with a bottom-right-anchored thumb and
  shows larger screens grow the "Ow" red zone, not the green zone.
- **Safe areas are engine-level:** Godot exposes DisplayServer.get_display_safe_area() and
  DisplayServer.get_display_cutouts(), with a documented platform limit (cutouts currently
  implemented only on Android; other platforms may return empty even when notched), plus
  Android Edge-to-Edge/Immersive Mode and iOS home-indicator guidance in the docs.
- **Session layout from a shipped port:** Dead Cells mobile moved the UI *off* the bottom
  edge to reserve it for virtual controls; virtual buttons won over tested gesture schemes;
  feasibility was proven with a rough device build before control/UI work.

## Evidence

| Claim | Source (direct URL) | Publisher / author | Date | Type | Verification |
|---|---|---|---|---|---|
| "a button needs a hit region of at least 44x44 pt — in visionOS, 60x60 pt — to ensure that people can select it easily, whether they use a fingertip, a pointer, their eyes, or a remote." | https://developer.apple.com/design/human-interface-guidelines/buttons | Apple HIG (Buttons) | current HIG as accessed 2026-10-27 | Platform guidelines (primary) | Verified (innerText extracted from rendered page via playwright) |
| Touch targets at least 48×48dp ≈ 9 mm regardless of screen size; recommended target 7–10 mm; "In most cases, there should be 8dp or more space between them"; 8 dp baseline grid; status bar 24 dp / toolbar 56 dp / list item 72 dp | https://m1.material.io/layout/metrics-keylines.html | Material Design (v1 docs, canonical static) | accessed 2026-10-27 | Platform guidelines (primary) | Verified |
| Android Accessibility Help: on-screen elements should be ≥48 dp wide/high "as described in the Material Design Accessibility guidelines"; TouchDelegate can enlarge touchable regions without resizing visuals | https://support.google.com/accessibility/android/answer/7101858?hl=en | Google Android Help | accessed 2026-10-27 | Platform documentation | Verified |
| Hoober study: 1,333 observations of public mobile-device use over two months ending January 8, 2013; of 780 touch-interaction observations: one-handed 49%, cradled 36%, two-handed 15%; voice call 22%, passive 18.9%; right thumb on screen 67% of one-handed cases (left 33%); green/yellow/red reach charts; users change grips "sometimes every few seconds" | https://web.archive.org/web/2020/https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php (Wayback copy of the UXmatters column) | Steven Hoober, UXmatters (Mobile Matters) | originally published ~2013-02; archive accessed 2026-10-27 | Field-study column | Verified via Wayback (live site unreachable: repeated 25 s timeouts, incl. playwright) |
| Hurff: thumb is anchored at the lower corner; Thumb Zone heat map vs each iPhone size; the "safe" green zone stays roughly the same as screens grow; big screens grow the "Ow" (red) zone | https://www.scotthurff.com/posts/how-to-design-for-thumbs-in-the-era-of-huge-screens | Scott Hurff (blog; also syndicated via Quartz) | 2014-09-18; accessed 2026-10-27 | UX essay | Verified (page opened) |
| Godot: DisplayServer.get_display_cutouts() "Returns an Array[Rect2] of Rect2, each of which is the bounding rectangle for a display cutout or notch… Note: Currently only implemented on Android and macOS. Other platforms will return an empty array even if they do have display cutouts"; get_display_safe_area() "Returns the unobscured area of the display where interactive controls should be rendered" | https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_displayserver.rst (canonical HTML: https://docs.godotengine.org/en/stable/classes/class_displayserver.html) | Godot docs repository (generated from engine docs) | accessed 2026-10-27 | Engine docs (primary) | Verified (raw .rst opened and read at both method descriptions) |
| Godot Android guidance: enable Screen > Edge to Edge; "make sure your application leaves enough space available for the status bar and navigation icons"; use get_display_safe_area / get_display_cutouts to query safe area; iOS: disable hide_home_indicator / hide_status_bar | https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/ui/creating_applications.rst | Godot docs repository | accessed 2026-10-27 | Engine docs (primary) | Verified (section read) |
| Godot Android export preset screen/edge_to_edge property: makes navigation and status bars translucent; warns "You should ensure that none of the application content is occluded by system elements by using the DisplayServer.get_display_safe_area() and get_display_cutouts() methods" | https://github.com/godotengine/godot-docs/blob/master/classes/class_editorexportplatformandroid.rst | Godot docs repository | accessed 2026-10-27 | Engine docs (primary) | Located via repo grep (github blob); same content stated in the two pages opened above |
| Dead Cells mobile: rough feasibility build first; gesture schemes prototyped then rejected in favor of virtual buttons; UI moved off the bottom edge ("that's where players have their hands") to free the bottom for controls; many buttons/UI elements reflowed for small screens | https://toucharcade.com/2019/05/07/dead-cells-mobile-blog-post | TouchArcade / Jared Nelson (reporting Playdigious's Laura Saada) | 2019-05-07; accessed 2026-10-27 | Named mobile outlet + developer postmortem | Verified (opened) |

## Analysis
The layout contract for a portrait game is now fully sourced: 44 pt / 48 dp hit regions,
~9 mm physical targets, 8 dp spacing, thumb-owned bottom band, safe-area insets from
DisplayServer — and a shipped 2D action port resolving the same problem we face: buttons
not gestures, hand-clean bottom edge, feasibility before polish. Hoober's grip-switching
finding (users change holds every few seconds) explains why a portrait exploration game
should tolerate both one-hand and two-hand grips rather than assuming one.

Absent primary evidence this pass: **typography minimums specific to 720×1280 pixel-art
UI in games** (the Material typography scale is web/app-oriented and was not opened here);
HUD-density studies for exploration games (no academic source openable). Bridging evidence
is indirect: Dead Cells' port used custom reflow; Void Bastards deliberately kept its loop
short (see `exploration_narratives.md`). Label any typography choice as design judgement.

## Contradictions and gaps
- Apple HIG extracts 44 pt while Material extracts 48 dp. These are different units and
  platforms, not a contradiction; both describe the same mechanism: Apple's 44 pt is a hit
  region (not visual size), and Material's 48 dp is the total touch target including padding
  ("Touch target on both: 48dp; Icon: 24dp").
- Hoober's study is 2013-era: thumbs on 2013 devices; larger current screens make the red
  zone worse (Hurff 2014). Treat percentages as a floor, not a guarantee, for 720×1280
  portrait games.
- uxmatters' live domain was unreachable on 2026-10-27 (three attempts; the Wayback copy is
  the citation).
- Godot cutouts: "only implemented on Android and macOS" — iOS support falls back to
  display-safe-area or nothing; verify per-device behavior at integration rather than
  claiming iOS cutout coverage.

## Implications for Beyond the Void
*Evidence says:*
1. Hit-region floor: 44 pt / 48 dp for every interactive control; virtual stick region
   needs a magnified hit radius (TouchDelegate analog) if the visual size must remain small.
2. Reserve the bottom band for controls and reflow status/objective UI to the top (Dead
   Cells); assume mixed grips (Hoober) so layouts work with a thumb anchored low-left or
   low-right.
3. Query safe area via DisplayServer.get_display_safe_area()/get_display_cutouts() and
   apply Edge-to-Edge guidance from the docs — never hard-code notch offsets.
4. Feasibility check before UI polish on the lowest supported device (Dead Cells port order).

*My judgement (not sourced):* at 720×1280, aim for world-readable helpers at a stride —
target 44×44 pt-ish hit boxes for HUD buttons, a two-step inventory/palette separation by
tab (not deep menus), and one-line objective text whose typography must be validated at
each device class; treat method-sized typography as unsourced and test it.

## Sources
- https://developer.apple.com/design/human-interface-guidelines/buttons — accessed 2026-10-27 (playwright text)
- https://m1.material.io/layout/metrics-keylines.html — accessed 2026-10-27
- https://support.google.com/accessibility/android/answer/7101858?hl=en — accessed 2026-10-27
- https://web.archive.org/web/2020/https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php — accessed 2026-10-27 (Wayback; live cite dead)
- https://www.scotthurff.com/posts/how-to-design-for-thumbs-in-the-era-of-huge-screens — accessed 2026-10-27
- https://raw.githubusercontent.com/godotengine/godot-docs/master/classes/class_displayserver.rst — accessed 2026-10-27 (canonical HTML: docs.godotengine.org class page)
- https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/ui/creating_applications.rst — accessed 2026-10-27
- https://github.com/godotengine/godot-docs/blob/master/classes/class_editorexportplatformandroid.rst — located via gh_grep (blob not fetched live)
- https://toucharcade.com/2019/05/07/dead-cells-mobile-blog-post — accessed 2026-10-27
- https://book.leveldesignbook.com/process/combat/enemy (bottom-edge controls corroborating claim in Dead Cells context) — not cited here beyond §3 file

## Confidence
**High** for touch target sizes, safe-area API, and the Dead Cells port decisions (all
primary or named-outlet pages opened). **Medium** for Hoober reach statistics (per-copy
Wayback, 2013-era). **Low/none** for game-specific typography minimums — deliberately not
claimed.
