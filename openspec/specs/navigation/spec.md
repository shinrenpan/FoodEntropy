# navigation Specification

## Purpose

The push-based `AppRouter` and the centralised `Deeplink` routing that sit on top of the single navigation stack `app-shell` assembles. Push is deliberate, not incidental: Home has no `@Query` and refreshes by re-fetching in its appearance callback, which a pop provides for free — do not convert this to present-based navigation without replacing that refresh mechanism. The router stays stateless by recording each destination's arrival transition on the destination itself, which is what lets `back` resolve pop-versus-dismiss without any caller ever branching on it.

## Requirements

### Requirement: ViewModels emit navigation intent; HostControllers execute it

The system SHALL have each feature ViewModel expose an `onRoute` closure carrying that feature's own `Router` enum, and SHALL have the feature's HostController wire that closure and translate each case into an `AppRouter` call. ViewModels SHALL NOT import UIKit, hold view controllers, or perform navigation themselves.

#### Scenario: Tapping a food row opens the edit form

- **WHEN** the user taps a row in the Home list
- **THEN** the Home ViewModel emits its edit route case, and the Home HostController asks `AppRouter` to navigate to the form for that item

#### Scenario: A ViewModel's navigation intent is unit-testable without UIKit

- **WHEN** a test drives a ViewModel action that should navigate
- **THEN** the test can assert on the `Router` case delivered to `onRoute` without instantiating any view controller

---



<!-- @trace
source: baseline-navigation
updated: 2026-08-08
code:
  - Sources/App/AppRouter.swift
  - Sources/App/Deeplink.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/Home/HomeHostController.swift
  - Sources/Features/FoodForm/FoodFormHostController.swift
  - Sources/Features/Settings/SettingsHostController.swift
-->

---
### Requirement: AppRouter is a stateless main-actor singleton that derives context from the source

The system SHALL implement `AppRouter` as a `@MainActor` singleton that holds no navigation controller, window, or view controller, and SHALL derive the navigation stack from the `source` view controller passed to each call. All navigation between the app's own screens SHALL be confined to `AppRouter`; feature code SHALL NOT call `pushViewController`, `present`, or `dismiss` on its own screens. Dismissing a system-owned picker from its own delegate callback — where the system controller manages its own lifecycle — is not app navigation and is exempt.

#### Scenario: Navigating derives the stack from the caller

- **WHEN** a HostController asks `AppRouter` to navigate to a destination
- **THEN** the router uses that source's own navigation controller, so the destination lands on the app's one stack without the caller naming it

#### Scenario: Navigating from a controller outside any stack fails loudly in debug

- **WHEN** a navigation call is made from a source that has no navigation controller
- **THEN** no navigation occurs and a debug-build assertion failure signals the misuse

---
### Requirement: The arrival transition is recorded on the destination so back resolves pop versus dismiss

The system SHALL record, on the destination view controller itself, the transition style by which it was shown, and `back` SHALL use that recorded style to choose between dismissing and popping. HostControllers SHALL always request `back` and SHALL NOT branch on presentation style themselves.

#### Scenario: Closing a pushed screen pops it

- **WHEN** a screen that arrived by push requests `back`
- **THEN** the navigation stack pops and the previous screen is revealed

#### Scenario: Closing a sheet dismisses it

- **WHEN** a screen that arrived as a sheet requests `back`
- **THEN** the sheet is dismissed rather than popped

#### Scenario: A destination with no recorded style defaults to push behaviour

- **WHEN** a destination is shown without an explicitly recorded transition style and later requests `back`
- **THEN** it is treated as a push arrival and pops

---



<!-- @trace
source: baseline-navigation
updated: 2026-08-08
code:
  - Sources/App/AppRouter.swift
  - Sources/App/Deeplink.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/Home/HomeHostController.swift
  - Sources/Features/FoodForm/FoodFormHostController.swift
  - Sources/Features/Settings/SettingsHostController.swift
-->

---
### Requirement: Modal web content is shown as a page sheet

The system SHALL present modal web content as a page sheet through `AppRouter`, optionally constrained to given detents, rather than as a full-screen push.

#### Scenario: Opening the privacy policy

- **WHEN** the user taps the privacy policy row in Settings
- **THEN** the hosted policy page appears as a page sheet the user can dismiss by pulling down, leaving Settings underneath

---



<!-- @trace
source: baseline-navigation
updated: 2026-08-08
code:
  - Sources/App/AppRouter.swift
  - Sources/App/Deeplink.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/Home/HomeHostController.swift
  - Sources/Features/FoodForm/FoodFormHostController.swift
  - Sources/Features/Settings/SettingsHostController.swift
-->

---
### Requirement: The interactive back gesture is enabled only for the default push transition

The system SHALL allow the interactive pop gesture only when the navigation stack holds more than one view controller and the top view controller arrived by the default push transition, and SHALL apply the same condition to the content-based pop gesture available from iOS 26.

#### Scenario: Swiping back from a pushed screen works

- **WHEN** the user swipes from the screen edge on a screen that arrived by push, with a previous screen in the stack
- **THEN** the gesture begins and pops the screen

#### Scenario: Swiping back from a custom-transition screen is refused

- **WHEN** the user swipes from the screen edge on a screen that arrived by a custom transition
- **THEN** the gesture does not begin, so a cancelled swipe cannot leave the screen mid-transition

#### Scenario: Swiping back at the root of the stack is refused

- **WHEN** the user swipes from the screen edge on the home screen, which is the root of the stack
- **THEN** the gesture does not begin

---
### Requirement: Leaving the app is not routed through AppRouter

The system SHALL open destinations outside the app — such as the system Settings page for this app's notification permissions — through the system's URL-opening API directly, and SHALL NOT route them through `AppRouter`.

#### Scenario: Sending the user to notification settings

- **WHEN** the user follows the notification-permission guidance in Settings
- **THEN** the system Settings app opens at this app's notification page, and no in-app navigation occurs

---



<!-- @trace
source: baseline-navigation
updated: 2026-08-08
code:
  - Sources/App/AppRouter.swift
  - Sources/App/Deeplink.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/Home/HomeHostController.swift
  - Sources/Features/FoodForm/FoodFormHostController.swift
  - Sources/Features/Settings/SettingsHostController.swift
-->

---
### Requirement: Deeplink parsing is centralised in one enum

The system SHALL parse every incoming URL through a single `Deeplink` enum initialiser that accepts only this app's URL scheme and returns nothing for an unrecognised host, and SHALL route every entry point — cold-launch URL, foreground URL, and notification tap — through that same enum and a single handler.

#### Scenario: Tapping an expiry notification opens the home list

- **WHEN** the user taps an expiry notification, whether the app was terminated, backgrounded, or in the foreground
- **THEN** the app opens and the stack comes to rest on the home list

#### Scenario: A notification without a deeplink payload still lands on the home list

- **WHEN** a notification is tapped whose payload carries no deeplink value
- **THEN** the app falls back to the home destination rather than ignoring the tap

#### Scenario: An unrecognised URL is ignored

- **WHEN** the app is opened with a URL whose scheme is not this app's, or whose host is not a known destination
- **THEN** no navigation occurs and the app stays where it was

#### Scenario: A cold-launch URL is handled after the window is ready

- **WHEN** the app is launched from a terminated state by a deeplink URL
- **THEN** the destination is applied after the window has been made key and visible, so the routing acts on an assembled interface

---
### Requirement: A single food item is a deeplink destination

The system SHALL accept a deeplink that names one food item, and SHALL open that item's detail for editing rather than stopping at the list. The destination SHALL be reachable by the same centralized parsing every other entry point uses, so that no entry point carries navigation logic of its own.

A deeplink naming an item that is no longer active SHALL land on the home list without reporting an error, because an item can legitimately be consumed, discarded, or deleted between the moment a link is offered and the moment it is followed.

Arriving at the item SHALL NOT depend on what was on screen when the deeplink was followed. When any screen is already presented above the home list, the system SHALL return to the home list **and** present the item's detail — returning to the list alone is a failure, not a partial success, because the user asked for an item and silently receives nothing.

#### Scenario: Following a link to an item

- **WHEN** an entry point supplies a deeplink naming an active food item
- **THEN** the stack returns to the home list and that item's detail is presented for editing

#### Scenario: Following a link to an item that is gone

- **WHEN** an entry point supplies a deeplink naming an item that has been consumed, discarded, or deleted
- **THEN** the stack returns to the home list, no detail is presented, and no error is surfaced

#### Scenario: Following two item links in succession

- **WHEN** a second item deeplink is followed while a detail is already presented
- **THEN** the second item's detail replaces the first rather than stacking on top of it

#### Scenario: Following an item link from any other screen

- **WHEN** an item deeplink is followed while a screen other than a food item detail is presented above the home list
- **THEN** that screen is removed and the item's detail is presented, rather than the stack coming to rest on the home list with nothing presented

#### Scenario: A malformed item link is rejected

- **WHEN** a URL names the item destination but carries no identifier, or one that is not a valid identifier
- **THEN** the URL resolves to no destination and nothing is navigated

##### Example: where the stack ends up

| On screen when the link is followed | Resulting stack |
| --- | --- |
| home list | home list, then the item's detail |
| another item's detail | home list, then the requested item's detail |
| settings | home list, then the requested item's detail |
| any of the above, item no longer active | home list only |

##### Example: item URL parsing

| URL | Resolves to |
| --- | --- |
| `foodentropy://home` | the home list |
| `foodentropy://item/<a valid identifier>` | that item's detail |
| `foodentropy://item/not-a-uuid` | nothing |
| `foodentropy://item` | nothing |
| `https://item/<a valid identifier>` | nothing |

---
### Requirement: Default navigation is a push onto the single navigation stack

The system SHALL default to a push transition when navigating to another screen, so that returning from that screen pops back and triggers the previous screen's appearance callback. There SHALL be one navigation stack for the whole app, and a pushed screen SHALL cover the full height the root screen occupied.

#### Scenario: Adding a food item and returning refreshes the list

- **WHEN** the user opens the add form from the home screen, saves, and the form closes
- **THEN** the home screen is revealed by a pop and its list reflects the newly added item

#### Scenario: A pushed screen owns the full screen

- **WHEN** any screen is pushed
- **THEN** no persistent bottom bar remains beneath it, because the root carries none

#### Scenario: Returning from settings refreshes the list

- **WHEN** the user opens settings from the home screen and then taps back
- **THEN** the home screen is revealed by a pop and reloads its data, the same way it does when returning from the form
