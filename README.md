# FoodEntropy (食熵)

> 🚧 **In Development** — specs complete, implementation starting.

A food-expiry tracking iOS app. Record groceries, track expiry dates, and get a
local notification on the day something expires — so less food goes to waste
because you forgot about it.

**"Entropy"** — food left unmanaged drifts toward disorder over time. The name
captures the core idea: *if you don't manage it, it goes bad.*

## Tech Stack

- **UI:** SwiftUI (bridged to a UIKit Router via HostControllers)
- **Persistence:** SwiftData (local) + CloudKit (opt-in iCloud sync)
- **Architecture:** MVVMC
- **Notifications:** UserNotifications (local)
- **Monetization:** free + ads (Google AdMob), one-time IAP to remove ads
- **Target:** iPhone only · iOS 26+ · portrait · light/dark

## Architecture Highlights

- **MVVMC layering:** `@Model` (persistence DTO) → `SwiftDataManager` (`toDomain()`)
  → ViewModel → State → View. ViewModels never touch SwiftData `@Model` directly.
- **CloudKit-safe schema** by construction (defaulted/optional attributes, no unique
  constraints) so sync can be toggled on/off cleanly.
- **Opt-in iCloud sync** (default off) — user data is never silently uploaded.
- **No third-party analytics/crash SDK** — Xcode Organizer + App Store Connect only.

## Spec-Driven Development

This project was designed spec-first. Every decision — and the reasoning behind it —
lives in [`specs/`](./specs/) before any code was written:

| Doc | Scope |
|-----|-------|
| [`00-constitution.md`](./specs/00-constitution.md) | Non-negotiable platform / architecture / language constraints |
| [`01-navigation.md`](./specs/01-navigation.md) | Tabs, screens, navigation flow |
| [`02-architecture.md`](./specs/02-architecture.md) | Data model, SwiftData/CloudKit, images, notifications, IAP |
| [`03-screens/`](./specs/03-screens/) | Per-screen State / Action / UI specs |
| [`04-tasks.md`](./specs/04-tasks.md) | Phased implementation task list |

`specs/` is the single source of truth. [`specs/archive/Spec.md`](./specs/archive/Spec.md)
is the original product seed and is now superseded.

## Status

- [x] Product spec & SDD design (constitution → tasks)
- [ ] Data layer (SwiftData model + manager)
- [ ] Core screens (Home / Form / Analytics / Settings)
- [ ] Notifications, IAP, ads
- [ ] iCloud sync verification
- [ ] App Store submission

## Screenshots

_Coming soon._

## Build

_Requirements and build steps will be added once the Xcode project lands._

## License

[MIT](./LICENSE) © 2026 Shinren Pan
