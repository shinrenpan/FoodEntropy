<!-- SPECTRA:START v1.3.0 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Skills

Each `/spectra-*` skill carries its own trigger description; these are the groups:

- Shape and plan → `/spectra-discuss`, `/spectra-propose`
- Continue tasks for an identified change → `/spectra-apply`
- Update requirements or plans for an identified change → `/spectra-ingest`
- Quality gate → `/spectra-verify`, `/spectra-review`, `/spectra-analyze`, `/spectra-audit`, `/spectra-drift`, `/spectra-debug`
- Finish → `/spectra-archive`, `/spectra-commit`

Explicit skill invocation takes precedence. Apply existing authorization within its unchanged scope.

## Workflow

discuss? → propose → apply ⇄ ingest → verify / review → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? Plan mode → `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `/spectra-apply` and `/spectra-ingest` skills disclose parking and restore when the named operation is already explicitly requested; respect a known refusal, otherwise ask for missing authorization.

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
- All user-facing strings go through **String Catalog**. Never hardcode strings.
  **English is the source language** — literals in code are English, and every entry carries a
  `zh-Hant` translation. Source and fallback are both `en` (`sourceLanguage`,
  `developmentLanguage`, `CFBundleDevelopmentRegion`); keep them identical. When they differ, the
  source language has no compiled strings file of its own and its users silently get the fallback
  instead — the build stays green, nothing warns you.
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

## Shipping

Release runs from a local, git-ignored script (`scripts/release_testflight.sh`): `xcodegen` →
`xcodebuild archive` → `-exportArchive` → `xcrun altool --upload-app`. App Store Connect API key
identifiers live in shell environment variables (`ASC_KEY_ID`, `ASC_ISSUER_ID`) and the `.p8` stays
outside the repo, so no credential is ever committed. The script is deliberately not checked in: it
depends on this author's team, certificates, and ASC account, so it would not run for anyone else.

Three things that cost real time to discover, recorded here because the script that encodes them is
not in the repo:

- **Homebrew's rsync 3.x breaks `-exportArchive`** with a bare "Copy failed". Force Apple's
  openrsync by prefixing the invocation with `PATH=/usr/bin:/bin:/usr/sbin:/sbin`.
- **A CLI `archive` signed with an Apple Development identity rewrites `aps-environment` to
  `development`**, even when the Release configuration sets `production`. That is the provisioning
  profile's constraint, not a project misconfiguration — confirm with
  `xcodebuild -showBuildSettings -configuration Release`, and check the real value on the exported
  `.ipa` (unzip first; `codesign -d` cannot read a `.ipa` directly).
- **Build numbers must be unique per marketing version.** Bump `CURRENT_PROJECT_VERSION` in
  `project.yml` before re-uploading the same version; nothing does it automatically.

Automatic signing suffices here (CloudKit, App Groups, Push). An app with Sign in with Apple cannot
use cloud signing for export and needs manually minted profiles instead — not a concern for this
project, noted only because the sibling project it was adapted from does.

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
