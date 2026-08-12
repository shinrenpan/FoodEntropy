<!-- SPECTRA:START v1.0.2 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `/spectra-*` skills when:

- A discussion needs structure before coding → `/spectra-discuss`
- User wants to plan, propose, or design a change → `/spectra-propose`
- Tasks are ready to implement → `/spectra-apply`
- There's an in-progress change to continue → `/spectra-ingest`
- User asks about specs or how something works → `/spectra-ask`
- Implementation is done → `/spectra-archive`
- Commit only files related to a specific change → `/spectra-commit`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? Plan mode → `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `/spectra-apply` and `/spectra-ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

# FoodEntropy (食熵)

Food-expiry tracking iOS app. Records groceries, tracks expiry dates, sends a local
notification on the expiry day to reduce food waste.

## Source of truth

**`openspec/specs/` is the source of truth.** Read the relevant capability spec before
implementing; all new work goes through the `/spectra-*` workflow above.
`openspec/specs/README.md` is the capability map — start there to see how they connect.

v1.0.0 predates Spectra, so its capabilities were backfilled from the shipped code as
`baseline-*` changes (archived under `openspec/changes/`). The pre-Spectra design documents
that served as source material have been removed; they remain in the git history, but they
are **not** a second source of truth and parts of them contradict the shipped app.

**All pending work lives in `openspec/changes/`** — not in GitHub issues, not in a task file.
A change proposal is the right home even when the work is blocked or its scope is still open:
state what is decided, what is not, and what unblocks it. This keeps everything the
`/spectra-*` workflow can read in one place.

## Non-negotiable rules (from the constitution)

- Platform: **iPhone only**, **iOS 26+**, portrait-locked, dark mode supported.
- Architecture: **MVVMC**. Layering: `@Model` (persistence DTO) → `SwiftDataManager` (`toDomain()`)
  → ViewModel → State → View.
- ViewModel / State **never hold SwiftData `@Model`** — only Domain Models.
- SwiftData `@Model` must be **CloudKit-safe**: every attribute has a default value or is optional,
  no `@Attribute(.unique)`, relationships optional — even when sync is off.
- All user-facing strings go through **String Catalog** (zh-Hant first). Never hardcode strings.
  Every entry needs **both** a `zh-Hant` and an `en` entry — including `zh-Hant`, whose value
  equals its key. Those look redundant during stale cleanup and **must not be deleted**: without
  them `zh-Hant.lproj` has no compiled strings file, and since the bundle's fallback is `en`
  (`CFBundleDevelopmentRegion`), Chinese users silently get English. The build stays green either
  way — nothing warns you.
- **Swift Concurrency strict mode.**
- Navigation goes through the **Router**; do not bypass it.
- Third-party deps: **Google AdMob only**. No third-party analytics/crash SDK
  (use Xcode Organizer + App Store Connect Analytics).

## Follow existing MVVMC skills

`mvvmc-model`, `mvvmc-viewmodel`, `mvvmc-view`, `mvvmc-hostcontroller`, `mvvmc-navigation`,
`mvvmc-testing`, `swift-concurrency`.

## Key domain facts

- Food status has two axes: **stored** `RecordStatus` (active/consumed/wasted) and **computed**
  `ExpiryStatus` (fresh / nearExpiry(0–3d) / expired(<0d)). ExpiryStatus is never persisted.
- Row exits: 延長 (stay active) / 已使用 (consumed) / 丟棄 (wasted) / 刪除 (hard delete, no record).
- iCloud sync is **opt-in, default off, applies on next launch**.
- Notifications fire at **09:00 on the expiry day**, one per item, permission requested on first save.

## Out of scope

Deliberate non-goals. Do not propose these as gaps, and do not add tasks or specs for them
unless the author asks.

- **Accessibility is not a goal of this project.** No spec or constitution rule has ever
  required it. About ten `accessibility*` modifiers exist across four view files (chart hidden
  from VoiceOver, ring-centre and currency labels, decorative icons hidden) — those were added
  incidentally during `add-price-tracking` and are **kept**: they work, they carry no
  maintenance cost, and removing them would risk already-shipped UI for no gain. What stops is
  the *expansion*: no accessibility capability, no VoiceOver verification tasks on new work, no
  treating missing coverage as a defect. The widget not announcing the ring-centre total is a
  known, accepted difference. When refactoring, preserve the existing behaviour if convenient;
  do not verify it as an acceptance criterion.
