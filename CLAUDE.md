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

**`openspec/specs/` is the source of truth.** A capability with a spec there wins over anything
in the legacy `specs/` directory. New work goes through the `/spectra-*` workflow above.

**Migration in progress** — v1.0.0 predates Spectra, so its capability specs are being backfilled
as `baseline-*` changes. Until that finishes, the pre-Spectra design documents remain as *source
material* (not a second source of truth):

- `specs/00-constitution.md` — non-negotiable platform/architecture/language constraints
- `specs/01-navigation.md` — tabs, screens, navigation flow
- `specs/02-architecture.md` — data model, SwiftData/CloudKit, images, notifications, IAP
- `specs/03-screens/*.md` — per-screen State / Action / UI specs
- `specs/04-tasks.md` — phased implementation task list + v1.1 backlog
- `specs/README.md` — index + status of each spec
- `specs/archive/Spec.md` — **superseded origin seed**, do NOT implement from it

`specs/` is removed once every capability listed in `openspec/specs/README.md` has been backfilled.

## Non-negotiable rules (from the constitution)

- Platform: **iPhone only**, **iOS 26+**, portrait-locked, dark mode supported.
- Architecture: **MVVMC**. Layering: `@Model` (persistence DTO) → `SwiftDataManager` (`toDomain()`)
  → ViewModel → State → View.
- ViewModel / State **never hold SwiftData `@Model`** — only Domain Models.
- SwiftData `@Model` must be **CloudKit-safe**: every attribute has a default value or is optional,
  no `@Attribute(.unique)`, relationships optional — even when sync is off.
- All user-facing strings go through **String Catalog** (zh-Hant first). Never hardcode strings.
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
