# notification Specification

## Purpose

The expiry reminder — without it this app is just a list the user maintains by hand. Its central design choice is that the schedule is never tracked per item: every reconciliation wipes all pending requests and rebuilds from the current active set, which collapses schedule, cancel, and reschedule into one operation and makes a missed code path incapable of leaving a ghost reminder behind. Do not "fix" this by adding per-item cancellation. Two limits shape the rest: iOS silently discards pending notifications beyond 64 per app (so the app schedules 60, soonest-expiry first), and the permission prompt only ever appears once — which is why it is spent on the moment the user saves their first item rather than on launch.

## Requirements

### Requirement: One notification per item, fired at nine in the morning on its expiry day

The system SHALL schedule a separate local notification for each active food item, timed for nine in the morning on that item's expiry date, SHALL name the item in the notification body, and SHALL use the item's identifier as the notification identifier. All notification text SHALL come from the String Catalog.

#### Scenario: An item expiring in a few days is announced on the day

- **WHEN** an item's expiry date arrives
- **THEN** a notification naming that item is delivered at nine that morning

#### Scenario: Several items expiring the same day each get their own notification

- **WHEN** three items share an expiry date
- **THEN** three separate notifications are delivered, each naming its own item

---



<!-- @trace
source: baseline-notification
updated: 2026-08-08
code:
  - Sources/Core/Notification/NotificationService.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: Scheduling is reconciled by rebuilding, not by tracking individual changes

The system SHALL, on every reconciliation, remove all pending notification requests and rebuild the schedule from the current set of active items, and SHALL reconcile after any change to the data and when the app comes to the foreground. Individual data operations SHALL NOT schedule or cancel notifications of their own.

#### Scenario: Resolving an item removes its reminder

- **WHEN** the user marks an item consumed or wasted, or deletes it
- **THEN** no notification for that item is delivered afterwards, because the rebuilt schedule no longer contains it

#### Scenario: Changing an expiry date moves the reminder

- **WHEN** the user edits or extends an item's expiry date
- **THEN** the reminder is delivered on the new date and not on the old one

#### Scenario: Returning to the app repairs a stale schedule

- **WHEN** the app comes to the foreground after days have passed
- **THEN** the schedule is rebuilt from the current active items

---



<!-- @trace
source: baseline-notification
updated: 2026-08-08
code:
  - Sources/Core/Notification/NotificationService.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: Scheduling respects the system limit by preferring the soonest expiries

The system SHALL schedule no more than a fixed maximum below the operating system's per-app pending-notification limit, and SHALL select which items to schedule by ordering candidates by fire time ascending and taking the earliest.

#### Scenario: More items than the limit

- **WHEN** the user has more active items with future fire times than the maximum
- **THEN** the items expiring soonest are scheduled, and the rest are left unscheduled until a later reconciliation brings them into range

#### Scenario: Consuming a near item makes room for a later one

- **WHEN** an item within the scheduled set is resolved and reconciliation runs
- **THEN** the next-soonest previously unscheduled item takes its place

---



<!-- @trace
source: baseline-notification
updated: 2026-08-08
code:
  - Sources/Core/Notification/NotificationService.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: Items whose fire time has already passed are not scheduled

The system SHALL exclude from scheduling any item whose fire time is not in the future.

#### Scenario: Recording a same-day item in the afternoon

- **WHEN** the user adds an item that expires today, after nine in the morning has already passed
- **THEN** no notification is scheduled for it, and it does not occupy one of the limited scheduling slots

#### Scenario: Recording an already-expired item

- **WHEN** the user adds an item whose expiry date is in the past
- **THEN** no notification is scheduled for it

---



<!-- @trace
source: baseline-notification
updated: 2026-08-08
code:
  - Sources/Core/Notification/NotificationService.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: Notification permission is requested at the first save, and only when undecided

The system SHALL request notification authorisation the first time the user saves a food item rather than at launch, SHALL request it only while the permission state is undecided, and SHALL treat provisional and ephemeral authorisation as authorised.

#### Scenario: The prompt appears in context

- **WHEN** the user saves their first food item
- **THEN** the system permission prompt appears, with the purpose evident from what they just did

#### Scenario: A later save does not prompt again

- **WHEN** the user saves another item after the permission has been decided either way
- **THEN** no prompt appears

---



<!-- @trace
source: baseline-notification
updated: 2026-08-08
code:
  - Sources/Core/Notification/NotificationService.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: Once permission is decided, the app directs the user to system settings

The system SHALL, when the user acts on the notification row in Settings, request authorisation directly if the state is undecided, and otherwise open this app's page in the system Settings app.

#### Scenario: A user who previously denied wants notifications

- **WHEN** the user taps the notification row having previously denied permission
- **THEN** the system Settings app opens at this app's notification page, since the in-app prompt can no longer appear

#### Scenario: A user who has never been asked taps the row

- **WHEN** the user taps the notification row while the permission state is undecided
- **THEN** the system permission prompt appears rather than the Settings app opening

---



<!-- @trace
source: baseline-notification
updated: 2026-08-08
code:
  - Sources/Core/Notification/NotificationService.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: Notifications carry a deeplink payload and are shown even in the foreground

The system SHALL attach a deeplink value to each notification's payload identifying the destination to open, and SHALL present expiry notifications as a banner with sound even while the app is in the foreground.

#### Scenario: Tapping a notification opens the intended destination

- **WHEN** the user taps an expiry notification
- **THEN** the app opens at the destination named in the payload

#### Scenario: A reminder arrives while the app is open

- **WHEN** an expiry notification fires while the user is using the app
- **THEN** it is still presented as a banner with sound rather than being suppressed

---



<!-- @trace
source: baseline-notification
updated: 2026-08-08
code:
  - Sources/Core/Notification/NotificationService.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: The immediate-fire test mode exists only in debug builds

The system SHALL confine the immediate-fire scheduling mode — which shortens the trigger and skips the past-fire-time filter — to `#if DEBUG` blocks, and SHALL NOT use it for foreground reconciliation even in debug builds.

#### Scenario: A release build always schedules for the expiry morning

- **WHEN** a user of a release build adds a food item
- **THEN** the reminder is scheduled for nine on the expiry date, and nothing is delivered moments later

#### Scenario: Opening the app in a debug build does not fire a burst of notifications

- **WHEN** a debug build comes to the foreground and reconciles
- **THEN** reconciliation uses the normal scheduling behaviour, so merely opening the app delivers nothing

---



<!-- @trace
source: baseline-notification
updated: 2026-08-08
code:
  - Sources/Core/Notification/NotificationService.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: The service can be constructed inactive for testing

The system SHALL support constructing the notification service in an inactive state in which every operation is a no-op.

#### Scenario: A unit test does not touch the notification centre

- **WHEN** a test exercises code that reconciles or queries authorisation through an inactive service
- **THEN** no request reaches the system notification centre and the test does not depend on notification permissions


<!-- @trace
source: baseline-notification
updated: 2026-08-08
code:
  - Sources/Core/Notification/NotificationService.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Settings/SettingsViewModel.swift
-->