# app-shell Specification

## Purpose

The UIKit-lifecycle shell every other capability runs inside: the `AppDelegate` + `SceneDelegate` entry point, the single composition root that builds and injects the app's stateful managers, the resilient store-creation chain that keeps a failed `ModelContainer` from becoming a launch crash loop, the two-tab root structure `navigation` operates on, and the platform envelope (iPhone-only, portrait, iOS 26+). SwiftUI starts below this layer, inside `UIHostingController`. Do not replace this with a SwiftUI `@main App` — MVVMC's router needs a real UIKit scene lifecycle, and the screenshot-mode escape hatch must never leave `#if DEBUG`, or the paid ad-removal entitlement becomes free.

## Requirements

### Requirement: The app boots through a UIKit AppDelegate and SceneDelegate

The system SHALL use a UIKit application lifecycle — an `@main` `AppDelegate` plus a `SceneDelegate` declared in `UIApplicationSceneManifest` — and SHALL NOT declare a SwiftUI `App` as its entry point. SwiftUI SHALL be hosted from `UIHostingController` subclasses downward.

#### Scenario: Cold launch builds the window from the scene delegate

- **WHEN** the app is launched from a terminated state
- **THEN** `SceneDelegate` receives `scene(_:willConnectTo:)`, creates the `UIWindow` for the connecting window scene, sets its root view controller, and makes it key and visible

#### Scenario: SwiftUI is reachable only through a hosting controller

- **WHEN** a screen's SwiftUI view is shown
- **THEN** it is the root view of a `UIHostingController` subclass, and no type in the app adopts the SwiftUI `App` protocol



<!-- @trace
source: baseline-app-shell
updated: 2026-08-08
code:
  - Sources/App/AppDelegate.swift
  - Sources/App/SceneDelegate.swift
  - project.yml
-->

---
### Requirement: SceneDelegate is the single composition root

The system SHALL create `SwiftDataManager` and `StoreManager` exactly once per scene, inside `SceneDelegate`, and SHALL inject them into HostControllers, which pass them down to their ViewModels. HostControllers and ViewModels SHALL NOT construct either manager themselves, and neither manager SHALL be exposed as a global singleton.

#### Scenario: Both tabs share one manager and one store instance

- **WHEN** the root tab bar controller is assembled with a Home tab and a Settings tab
- **THEN** both HostControllers receive the same `StoreManager` instance, so an ad-removal entitlement observed by Settings is the same entitlement Home reads

#### Scenario: A purchase made in Settings takes effect on Home

- **WHEN** the user completes the "remove ads" purchase on the Settings tab and switches to the Home tab
- **THEN** the Home tab reflects the ad-removed state without an app restart, because both tabs observe one shared store



<!-- @trace
source: baseline-app-shell
updated: 2026-08-08
code:
  - Sources/App/AppDelegate.swift
  - Sources/App/SceneDelegate.swift
  - project.yml
-->

---
### Requirement: Store creation degrades rather than failing the launch

The system SHALL create its data store through a resilient chain that attempts, in order, a CloudKit-backed container, a local-only container, and finally an in-memory container. Store creation SHALL NOT propagate an error that prevents the app from launching.

#### Scenario: CloudKit is unavailable while sync is enabled

- **WHEN** the user's iCloud sync preference is on but the CloudKit-backed container cannot be created
- **THEN** the app still launches and operates against a local-only store, leaving the user able to reach Settings and turn sync off

#### Scenario: Local store creation also fails

- **WHEN** neither the CloudKit-backed nor the local-only container can be created
- **THEN** the app still launches against an in-memory store rather than crashing at startup



<!-- @trace
source: baseline-app-shell
updated: 2026-08-08
code:
  - Sources/App/AppDelegate.swift
  - Sources/App/SceneDelegate.swift
  - project.yml
-->

---
### Requirement: The root is a two-tab controller with per-tab navigation stacks

The system SHALL use a `UITabBarController` as the window's root view controller, containing exactly two tabs — Home and Settings — and SHALL wrap each tab's root in its own `UINavigationController`. Tab titles SHALL come from the String Catalog.

#### Scenario: Launch shows both tabs with Home selected

- **WHEN** the app finishes launching
- **THEN** a tab bar with a Home tab and a Settings tab is shown, with Home selected

#### Scenario: Navigation depth is preserved per tab

- **WHEN** the user pushes a screen inside the Home tab and then switches to the Settings tab and back
- **THEN** the Home tab is still showing the pushed screen, because each tab owns a separate navigation stack



<!-- @trace
source: baseline-app-shell
updated: 2026-08-08
code:
  - Sources/App/AppDelegate.swift
  - Sources/App/SceneDelegate.swift
  - project.yml
-->

---
### Requirement: Debug-only environment switches are excluded from Release builds

The system SHALL confine every environment-variable escape hatch — including the screenshot mode that pre-grants the ad-removal entitlement, the mock-seeding switch, and the initial-tab override — to `#if DEBUG` compilation blocks, so that no such code path exists in a Release build.

#### Scenario: A Release build ignores the screenshot-mode entitlement override

- **WHEN** a Release build is launched with the screenshot-mode environment variable set
- **THEN** the ad-removal entitlement is determined solely by StoreKit, and ads are shown to a user who has not purchased removal

#### Scenario: A Release build ignores mock seeding and tab override

- **WHEN** a Release build is launched with the mock-seeding or initial-tab environment variables set
- **THEN** no mock data is created and the app opens on the Home tab



<!-- @trace
source: baseline-app-shell
updated: 2026-08-08
code:
  - Sources/App/AppDelegate.swift
  - Sources/App/SceneDelegate.swift
  - project.yml
-->

---
### Requirement: The window uses an opaque semantic background colour

The system SHALL set the window's background colour to a semantic system background colour rather than leaving it at its default.

#### Scenario: A custom transition does not reveal a black gap

- **WHEN** a custom modal or fade transition is running in light mode and the container view is briefly visible behind the animating views
- **THEN** the exposed area matches the system background colour rather than flashing black



<!-- @trace
source: baseline-app-shell
updated: 2026-08-08
code:
  - Sources/App/AppDelegate.swift
  - Sources/App/SceneDelegate.swift
  - project.yml
-->

---
### Requirement: The platform envelope is iPhone-only, portrait, iOS 26 or later

The system SHALL target iPhone only, SHALL support the portrait orientation only, SHALL require iOS 26 or later, SHALL build in Swift 6 language mode with complete strict-concurrency checking, and SHALL render correctly in both light and dark appearance.

#### Scenario: Rotating the device does not rotate the UI

- **WHEN** the user rotates the device to landscape
- **THEN** the interface stays in portrait

#### Scenario: Switching to dark appearance keeps the UI legible

- **WHEN** the system appearance changes between light and dark
- **THEN** every screen remains legible, with status colours distinguishable in both appearances



<!-- @trace
source: baseline-app-shell
updated: 2026-08-08
code:
  - Sources/App/AppDelegate.swift
  - Sources/App/SceneDelegate.swift
  - project.yml
-->

---
### Requirement: The Xcode project is generated from project.yml

The system SHALL treat `project.yml` as the single source of truth for project configuration and SHALL keep the generated `.xcodeproj` out of version control.

#### Scenario: A configuration change is made

- **WHEN** a build setting, entitlement, Info.plist key, or dependency needs to change
- **THEN** the change is made in `project.yml` and the project is regenerated, rather than edited in the Xcode project file

#### Scenario: A fresh clone is prepared for development

- **WHEN** the repository is cloned
- **THEN** no `.xcodeproj` is present until the project is generated from `project.yml`



<!-- @trace
source: baseline-app-shell
updated: 2026-08-08
code:
  - Sources/App/AppDelegate.swift
  - Sources/App/SceneDelegate.swift
  - project.yml
-->

---
### Requirement: Source files follow the MVVMC folder convention

The system SHALL organise sources as `Sources/App` for the shell and router, `Sources/Core` for cross-screen concerns grouped by subject, and `Sources/Features/<Feature>/` for each screen. Each feature folder SHALL contain that screen's HostController, View, ViewModel, and the ViewModel's models extension.

#### Scenario: A new screen is added

- **WHEN** a new screen is introduced
- **THEN** its HostController, View, ViewModel, and ViewModel models extension are placed together under a single folder named for that feature

#### Scenario: Logic is shared by more than one screen

- **WHEN** a concern is consumed by more than one screen
- **THEN** it lives under `Sources/Core` in a subfolder named for the subject, not inside any one feature folder


<!-- @trace
source: baseline-app-shell
updated: 2026-08-08
code:
  - Sources/App/AppDelegate.swift
  - Sources/App/SceneDelegate.swift
  - project.yml
-->