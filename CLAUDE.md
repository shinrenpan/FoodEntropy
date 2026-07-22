# FoodEntropy (食熵)

Food-expiry tracking iOS app. Records groceries, tracks expiry dates, sends a local
notification on the expiry day to reduce food waste.

## Source of truth

`specs/` is the single source of truth (Spec-Driven Development). Read it before implementing.
`specs/archive/Spec.md` is the **superseded origin seed** — do NOT implement from it.

- `specs/00-constitution.md` — non-negotiable platform/architecture/language constraints
- `specs/01-navigation.md` — tabs, screens, navigation flow
- `specs/02-architecture.md` — data model, SwiftData/CloudKit, images, notifications, IAP
- `specs/03-screens/*.md` — per-screen State / Action / UI specs
- `specs/04-tasks.md` — phased implementation task list
- `specs/README.md` — index + status of each spec

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
