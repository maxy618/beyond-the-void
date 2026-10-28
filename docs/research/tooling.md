# Tooling audit — Phase 0

Access date for every test below: **2026-10-27** (times UTC). All tests are real calls made
this session; result shapes were inspected directly. Nothing in this file is assumed from
documentation.

## Summary

| Tool family | Status | Verdict |
|---|---|---|
| `free_search` (search/fetch/fetch_batch/research/read_doc/extract_structured/engines/cache_search/compare/paper_graph) | works | Backbone for all web research |
| `free_search.download` | partially blocked | 403 on Wikipedia (robot policy); call sites other than Wikipedia untested |
| `fetch.fetch` | works | Good for plain pages, has `raw` + start_index paging |
| Built-in `webfetch` | partial | Works (Wikipedia OK); 403 on fandom.com and other bot-hostile sites |
| Built-in `websearch` | blocked | HTTP 403 on every call (2/2) — do not use; substitute `free_search.search` |
| `deepwiki` | works | Only `read_wiki_structure` / `read_wiki_contents` / `ask_wiki_question` exposed |
| `context7` | works | One transient ECONNRESET, succeeded on retry |
| `gh_grep.searchGitHub` | works | Repo-wide code pattern search with license field |
| `searchcode` | works | Clones on demand; large repos return `clone_in_progress` then succeed |
| `playwright` | works | Full browser: navigate, snapshot, evaluate — handles JS-heavy pages |
| `exa_research` | not present | No such namespace exists in this environment (verified via catalog search) |
| `memory` | works | Cross-session project memory |
| Video ingest | blocked | No video tool exists; `read` handles images/PDFs only — video review must use transcripts/developer write-ups and be marked BLOCKED otherwise |

Return-shape convention discovered: `free_search` tools return a **markdown string** by default
(meta lines: engines, dates, cache age) and parseable objects when `format: "json"`.
`deepwiki` wraps output in `{"result": string}`. The Code Mode `execute` output is
auto-truncated ~65k chars and archived to a file — always return trimmed slices.

## free_search

Operation: `tools.free_search.search({query, max_results, format, category, freshness, include_domains, exclude_domains, include_text, exclude_text})`
Status: works (2 calls). Returns engines used, result count, dated-count, and results with
title/URL/snippet/engines/score/site-date/source_type. JSON mode returns
`{query, engines[], cached, results[{title,url,snippet,engines,score,date_source,source_type}]}`.
Best use: first-pass discovery. `category: "forum"` is genuinely useful for player criticism;
`category: "pdf"|"paper"|"github"` for primary material.
Limitations: snippets only — every substantive claim still needs the page fetched; results
flagged `undated` carry no date; engine mix changes per query (bing/mojeek sometimes
"contributed nothing").
Evidence: `"No Man's Sky Atlas Path ending story acts"` → 8 results, top
`nomanssky.fandom.com/wiki/The_Atlas_Path` + Reddit thread. Date 2026-10-27.

Operation: `tools.free_search.fetch({url, render, force_refresh})`
Status: works (fandom page fetched from cache, 7,509 chars). Returns markdown string with
publisher-line (`published YYYY-MM-DD`), cache age, token estimate.
Best use: reading any single page; `render:"auto"` upgrades to browser when needed.
Limitations: cache can be up to ~1 day stale (saw "cached 19 hours ago") — use `force_refresh:true`
when freshness matters; some hosts refuse bots regardless of tool.
Evidence: `https://nomanssky.fandom.com/wiki/The_Atlas_Path` → full mission table (mission type,
requires, implemented). Date 2026-10-27.

Operation: `tools.free_search.fetch_batch({urls[], render})`
Status: works (3 URLs, 51,284 chars concatenated).
Best use: cross-checking 2–3 sources in one round trip.
Limitations: one giant markdown blob; page boundaries interleaved — fine for reading, parse
carefully when extracting quotes with citation.

Operation: `tools.free_search.research({question, depth, fetch})`
Status: works (only 2 sources for a niche question at depth 2).
Best use: orienting sweep of a new topic; returns a brief with numbered sources.
Limitations: shallow source count — NOT a substitute for the manual loop
search → fetch → cross-check; treat its summary as a list of leads.

Operation: `tools.free_search.read_doc({source, start, length})`
Status: works (fetched 75-page arXiv PDF, pageable slices "0:3000").
Best use: PDF/DOCX first-party material (papers, GDC slide PDFs? untested on slides).
Limitations: PDFs render page-wise; long PDFs need start-index walks; no image-only OCR guarantee
(scanned pages may be lost — treat as gap, not failure).

Operation: `tools.free_search.extract_structured({url})`
Status: works. Steam page returned schema.org microdata (Product: price 760 RUB,
aggregateRating "Very Positive", ratingValue 9/10, reviewCount 187196) plus OG tags.
Best use: prices, dates, ratings, metadata for time-stamped comparisons.
Limitations: only extracts what the page publishes in machine-readable form; JS-only pages may
need playwright first.

Operation: `tools.free_search.download({url})`
Status: **blocked on en.wikipedia.org**: exact error `403 Please respect our robot policy
https://w.wiki/4wJS...`. Alternative used: `fetch.fetch` fetched the same domain fine.
Status on other domains: untested — label accordingly if used.

Operation: `tools.free_search.engines({group})`
Status: works. Lists engines per group (web, news, paper, github, forum, …) with one-line notes
(e.g. brave "serves a proof-of-work captcha after a few calls", startpage "needs a browser
render, so it is slower").
Best use: choosing engines before retrying a failed search.

Operation: `tools.free_search.cache_search({query})`
Status: works (returns "no cached pages match" when empty — informative, not an error).
Best use: reusing pages already fetched this session without re-downloading.

Operation: `tools.free_search.paper_graph({paper, direction, limit})`
Status: works. arXiv id 2005.14165 → title, DOI, "cited by 16451", references list with DOIs;
warned "Not in Crossref: likely a DataCite DOI, so retraction notices could not be checked".
Best use: finding the citation graph around a design/CS paper.
Limitation: DOI lookups can be incomplete (Crossref vs DataCite).

Operation: `tools.free_search.compare({question, urls[]})`
Status: implemented; untested. Presumed useful for contradiction checks.

## fetch.fetch (plain)

Status: works (Wikipedia article fetched, 2,661 chars at max_length 2500).
Returns text/markdown with `max_length` cap and `start_index` paging, optional raw HTML.
Best use: fastest clean fetch when free_search cache is stale or the site dislikes crawlers
(often more permissive than free_search.download).
Limitation: no caching, no date stamps — record access dates yourself.

## Built-in webfetch (direct tool)

Status: partial. Call 1 fandom.com → `403 non-2xx`. Call 2 Wikipedia → full article.
Conclusion: usable but bot-hostile sites are excluded; rely on free_search/playwright there.

## Built-in websearch (direct tool)

Status: **blocked**. 2/2 calls → `HTTP 403`. No error detail beyond that. Substitution:
`free_search.search` (works, no key).

## deepwiki

Tools present: `read_wiki_structure`, `read_wiki_contents`, `ask_wiki_question`
(`list_wiki_repos` is mentioned by the server description but NOT exposed in this environment).

Operation: `tools.deepwiki.read_wiki_structure({repoName})`
Status: works ("godotengine/godot" → topic index: Build System, Scene System, Viewport System, …).
Best use: orientation of a GitHub repo before reading code.

Operation: `tools.deepwiki.ask_wiki_question({repoName, question})`
Status: works. Question about SceneTree deferred calls → explanation naming `MessageQueue`,
`flush()`, call sites in `SceneTree::process/physics_process` — plausible but AI-generated:
treat as secondary interpretation, verify against source before citing any claim.

## context7

Operation: `tools.context7["resolve-library-id"]`
Status: works on retry (first call failed `ECONNRESET: socket connection closed`).
"Godot" → `/godotengine/godot-docs` (46,403 snippets, benchmark 68.4, branches 4.5 & 4.7) and
`/godotengine/godot`.

Operation: `tools.context7["query-docs"]`
Status: works. SubViewport query → snippets with **direct source URLs**
(`godotengine/godot-docs/blob/master/tutorials/rendering/viewports.rst`), code + scenario notes.
Best use: quick engine-doc facts for the Godot-specific recommendations.

## gh_grep.searchGitHub

Status: works. `func _ready` + language GDScript → repo, path, URL, license, line-numbered
snippet groups. Filter by repo/org/language/path.
Best use: real-world code precedents (e.g. how other Godot projects validate spawns).
Limitation: live GitHub search index — not exhaustive; abuse can rate-limit.

## searchcode

Operation: `tools.searchcode.code_search({repository, query, ...})`
Status: works, but **clones on demand**: first call to godot-demo-projects returned
`{"code":"clone_in_progress","message":"Repository is being cloned (large repo)… retry in about
60 seconds"}`; retry succeeded → `{commit_sha, total_matches:32, results_returned:5, matches[]}`
with line numbers and context.
Also available: `code_analyze`, `code_file_tree`, `code_get_file`, `code_get_files`,
`code_find_usages`, `code_get_findings`.
Best use: precise, line-numbered evidence from a specific repo (commit SHA pins it).
Limitation: one-repo-per-call; large repos have a cold-start; exact repo URL required.

## playwright

Operation: `tools.playwright.browser_navigate` + `browser_snapshot` (25 tools available,
incl. `browser_evaluate`, `browser_run_code_unsafe`, `browser_take_screenshot`,
`browser_console_messages`).
Status: works. Navigated Steam store page (JS-heavy) → 65k-char accessibility snapshot;
page title rendered correctly.
Best use: pages that block crawlers or need JS; reading forum threads behind lazy-load.
Limitations: snapshot output is enormous — always pair with `browser_find` or `browser_evaluate`
to extract a specific element; browser locale followed host (Russian), so locale-dependent
pages may render non-English.

## exa_research

Status: **not present**. Catalog searches for "exa" across all namespaces return no matching
tools (`web_search_exa`, `web_fetch_exa`, `agent_run` do not exist). All exa-based steps in the
role brief must run on `free_search` + `fetch` + playwright instead. Recorded as a gap.

## memory

Operation: `tools.memory({mode:"add"}), ({mode:"search"})`
Status: works both ways. `add` → `{success, id, tags}`; `search` → matching memory with id,
content, tags. Project memory was empty before this audit.
Best use: carrying audit facts and research verdicts across sessions.

## Other servers present

- `godot_mcp` (21 tools), `godot-lsp`, `serena`, `aseprite` (123 tools), `shadcn`,
  `opencode` (session/worktree mgmt), `gh_grep`, `searchcode` — game-dev/code tools, not web
  research tools. `godot_mcp` can read the running game (evidence of runtime behaviour) but was
  NOT tested here: it requires the Godot editor running; research-only sessions should not
  launch the game. Marked out of scope for this audit.
- `tools.playwright` covers screenshots → images can be read back with built-in `read` for
  visual claims. Graphics-only (no video) inspection confirmed by tool inventory: **there is no
  video ingestion tool**; any video-based task must be marked with transcript/write-up evidence
  or BLOCKED.

## Decision defaults (from evidence, not assumption)

1. Discovery: `free_search.search` (plain + `category:` variants). Never built-in websearch.
2. Read a page: `free_search.fetch` (date-aware, cached) → `fetch.fetch`/webfetch when bot-blocked
   or stale → playwright for JS-heavy/login-free pages that still fail.
3. Forum/player criticism: `free_search.search` with `category:"forum"`, then playwright or
   fetch the thread.
4. PDF/DOCX: `free_search.read_doc` with page walks.
5. Code evidence: `gh_grep` (cross-repo) vs `searchcode` (one repo, pinned SHA) vs
   `deepwiki` (AI summary — verify before citing).
6. Engine/framework facts: `context7.query-docs` → verify against official docs page when the
   claim is load-bearing.
7. Prices/dates/metadata: `extract_structured`.
8. Cross-session continuity: `memory`.
