# persistence Specification

## Purpose

The SwiftData boundary: a `@Model` acting as this app's DTO (there is no backend), converted to domain values at the manager edge and never escaping past it. Nearly every constraint here follows from one premise — iCloud sync is a switch the user can flip at any moment — so the schema stays CloudKit-safe permanently, giving up database-level required fields and uniqueness in exchange for a switch that never needs a migration and never crashes on the day the user asks for a backup. Two behaviours here are easy to mistake for oversights and are not: resolving an item deliberately destroys its photo to keep history near-free, and every read failure returns an empty collection rather than surfacing an error.

## Requirements

### Requirement: The persisted model stays CloudKit-safe whether or not sync is on

The system SHALL give every non-optional persisted attribute a default value, SHALL NOT declare any attribute unique, and SHALL make any future relationship optional — regardless of whether iCloud sync is currently enabled. Required-field validation SHALL be performed by the entry form rather than by database constraints.

#### Scenario: Enabling sync on an existing local database succeeds

- **WHEN** a user who has been using the app with sync off enables iCloud sync and relaunches
- **THEN** the store is created against the same schema without migration, and the app launches normally

#### Scenario: A missing required value is rejected before it reaches the store

- **WHEN** the user tries to save a food item without a name
- **THEN** the form rejects the save, since the store itself would have accepted an empty string

---



<!-- @trace
source: baseline-persistence
updated: 2026-08-08
code:
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Image/ImageCompressor.swift
-->

---
### Requirement: Record status is persisted as a raw string and unknown values fall back to active

The system SHALL persist the record status as its raw string value, and SHALL interpret an unrecognised stored value as `active` when converting to the domain model.

#### Scenario: A value written by a newer version is read by an older one

- **WHEN** a record synced from another device carries a status string this version does not recognise
- **THEN** the item is presented as an active item rather than being discarded or causing a failure

---



<!-- @trace
source: baseline-persistence
updated: 2026-08-08
code:
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Image/ImageCompressor.swift
-->

---
### Requirement: The persistence layer never exposes its model type

The system SHALL convert every persisted entity to a domain model at the manager boundary, SHALL define that conversion on the entity itself, and SHALL NOT return, accept, or otherwise expose the persisted model type through the manager's public interface.

#### Scenario: A view model requests the active list

- **WHEN** a view model asks the manager for the current food items
- **THEN** it receives domain values it can hold and compare freely, with no context-bound persistence objects among them

#### Scenario: A view model is tested without a database

- **WHEN** a unit test drives a view model with domain values injected directly
- **THEN** no store, container, or persisted entity is required for the test to run

---



<!-- @trace
source: baseline-persistence
updated: 2026-08-08
code:
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Image/ImageCompressor.swift
-->

---
### Requirement: Data is delivered by explicit re-fetch, not by automatic observation

The system SHALL provide data through a main-actor manager that callers query explicitly, and SHALL NOT bind views directly to the store through automatic query observation.

#### Scenario: The list reflects a change made on another screen

- **WHEN** the user returns to the list after adding or editing an item on another screen
- **THEN** the list shows the change because the screen re-fetched on appearing, not because the store pushed an update

---



<!-- @trace
source: baseline-persistence
updated: 2026-08-08
code:
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Image/ImageCompressor.swift
-->

---
### Requirement: Query ordering is part of the data contract

The system SHALL return active items sorted by expiry date ascending and then by creation date ascending, and SHALL return resolved items sorted by resolution time from newest to oldest.

#### Scenario: Items expiring on the same day keep a stable order

- **WHEN** several items share an expiry date and the list is fetched repeatedly
- **THEN** their relative order is the same every time, ordered by when they were created

#### Scenario: The soonest expiry appears first

- **WHEN** the active list is fetched
- **THEN** the item closest to expiry — including any already past it — appears before items expiring later

---



<!-- @trace
source: baseline-persistence
updated: 2026-08-08
code:
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Image/ImageCompressor.swift
-->

---
### Requirement: Resolving an item records the resolution time and strips its photo

The system SHALL, when marking an item consumed or wasted, set its record status, record the time of resolution, and clear its stored image data. Deleting an item SHALL remove the record entirely, and editing an item SHALL NOT alter its record status.

#### Scenario: A consumed item stops occupying image storage

- **WHEN** the user marks an item with a photo as consumed
- **THEN** the record is retained with its resolution time, and its image data is no longer stored

#### Scenario: Editing does not resolve an item

- **WHEN** the user edits an active item's name, dates, or photo
- **THEN** the item remains active with no resolution time recorded

---



<!-- @trace
source: baseline-persistence
updated: 2026-08-08
code:
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Image/ImageCompressor.swift
-->

---
### Requirement: Photos are downscaled and compressed before they are stored

The system SHALL resize a captured or selected photo so its longest side does not exceed the configured maximum, SHALL render that resize at a scale of one so the pixel limit is honoured on high-density displays, SHALL encode it as JPEG at the configured quality, and SHALL store the result as external-storage data that participates in sync.

#### Scenario: A high-resolution photo is reduced before storage

- **WHEN** the user picks a photo far larger than the configured maximum dimension
- **THEN** the stored data is a downscaled JPEG of a few hundred kilobytes rather than the original image

#### Scenario: A photo already within the limit is not enlarged

- **WHEN** the user picks a photo whose longest side is already within the maximum
- **THEN** it is encoded without being resized

---



<!-- @trace
source: baseline-persistence
updated: 2026-08-08
code:
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Image/ImageCompressor.swift
-->

---
### Requirement: Read failures yield empty results and write failures reach the caller

The system SHALL return an empty collection when a fetch fails, without terminating the app.

When a save fails, the system SHALL raise a debug-build assertion **and** report the failure to its caller, so that each caller decides what to do.

Whether a caller is permitted to ignore that failure SHALL be decided by one test: what the interface looks like afterwards.

- A caller whose interface stays visible and unchanged after a failed write SHALL be permitted to ignore the failure, because the unchanged interface already tells the user nothing happened.
- A caller that dismisses, closes, or replaces its own interface once a write succeeds SHALL NOT ignore the failure, because that dismissal is the app's signal that the write happened. Such a caller SHALL keep its interface in place and tell the user the write did not happen.
- A caller that reports its own success to someone else — an assistant action speaking a confirmation, for instance — SHALL NOT treat an ignored failure as success.

Re-reading after a failed save SHALL NOT be used to detect it: the context still reports the pending in-memory change, so the read appears to succeed.

#### Scenario: The store cannot be read

- **WHEN** a fetch fails at runtime
- **THEN** the caller receives an empty collection and the app continues running

#### Scenario: A save fails during development

- **WHEN** a save fails in a debug build
- **THEN** an assertion failure surfaces the problem immediately to the developer

#### Scenario: A save fails in a release build

- **WHEN** a save fails in a release build
- **THEN** the failure reaches the caller rather than being discarded, and the app continues running

#### Scenario: A screen that stays put ignores a failed save

- **WHEN** a write fails on a screen that remains on display with the same content afterwards
- **THEN** the screen continues without an error of its own, because the unchanged content conveys that nothing was recorded

#### Scenario: A screen that closes on success cannot ignore a failed save

- **WHEN** a write fails on a screen that would have closed itself had the write succeeded
- **THEN** the screen stays open and reports the failure, because closing would tell the user the write happened

##### Example: applying the test to this app's writing callers

| Caller                              | Interface after a failed write | Ignoring permitted |
| ----------------------------------- | ------------------------------ | ------------------ |
| Item list row actions               | same list, item still present  | yes                |
| Item entry form                     | would have closed on success   | no                 |
| Assistant action spoken back to user | confirmation would be spoken  | no                 |

---
### Requirement: Schema evolution is additive only

The system SHALL evolve its persisted schema by adding attributes only, and SHALL NOT change the type of, or remove, an existing attribute.

#### Scenario: A new field is needed

- **WHEN** a future feature requires a new piece of data on a food item
- **THEN** it is added as a new optional or defaulted attribute, leaving existing attributes untouched, because deployed CloudKit schemas cannot be altered or removed


<!-- @trace
source: baseline-persistence
updated: 2026-08-08
code:
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Image/ImageCompressor.swift
-->

---
### Requirement: The recorded cost is persisted as an optional attribute and survives resolution

The system SHALL persist the recorded cost as an optional attribute, added without altering any existing attribute, and SHALL retain it when an item is marked consumed or wasted. Unlike the item's photo, the cost SHALL NOT be cleared on resolution.

#### Scenario: A resolved item keeps its cost

- **WHEN** the user marks an item that has a recorded cost as consumed or wasted
- **THEN** the stored record retains that cost, so it remains available to waste statistics — while its photo is still cleared as before

#### Scenario: Adding the attribute does not disturb existing records

- **WHEN** a user with existing food items updates to a version that introduces the cost attribute
- **THEN** their items load normally with no recorded cost, and no migration prompt or data loss occurs


<!-- @trace
source: add-price-tracking
updated: 2026-08-08
code:
  - Sources/Features/FoodForm/FoodFormViewModel+Models.swift
  - Tests/FoodEntropyTests/CurrencyFormatTests.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - CLAUDE.md
  - Sources/Features/Home/HomeView.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Core/Extensions/CurrencyFormat.swift
  - Tests/FoodEntropyTests/FoodFormViewModelTests.swift
  - Sources/Core/Components/FoodRowView.swift
  - Sources/Core/Domain/FoodItem.swift
  - Tests/FoodEntropyTests/SwiftDataManagerTests.swift
  - Sources/Core/Domain/FoodItemMocks.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/FoodForm/FoodFormView.swift
  - README.md
  - Sources/Features/Home/HomeViewModel.swift
  - Tests/FoodEntropyTests/HomeViewModelTests.swift
-->

---
### Requirement: Every attribute must be written at least once before deploying the schema

The system SHALL, before deploying a schema to the production environment, ensure each attribute — including optional ones — has actually been written with a value in the development environment, and SHALL verify the resulting field list rather than assuming the model definition was mirrored.

#### Scenario: An optional attribute that no record has ever set

- **WHEN** a new optional attribute exists in the model but no record has yet been saved with a value for it
- **THEN** no corresponding field exists in the development schema, and deploying at that point ships a production schema missing that field

#### Scenario: The missing field surfaces only later, in production

- **WHEN** a production schema lacks a field and a user's record sets that attribute
- **THEN** the value cannot sync, because production does not create fields on demand — and nothing in the app reports the failure

#### Scenario: Verifying before deployment

- **WHEN** preparing to deploy after adding attributes
- **THEN** each attribute is exercised with a real value first, and the development field list is checked against the model before the deployment is confirmed

<!-- @trace
source: add-price-tracking
updated: 2026-08-08
code:
  - Sources/Features/FoodForm/FoodFormViewModel+Models.swift
  - Tests/FoodEntropyTests/CurrencyFormatTests.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - CLAUDE.md
  - Sources/Features/Home/HomeView.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Core/Extensions/CurrencyFormat.swift
  - Tests/FoodEntropyTests/FoodFormViewModelTests.swift
  - Sources/Core/Components/FoodRowView.swift
  - Sources/Core/Domain/FoodItem.swift
  - Tests/FoodEntropyTests/SwiftDataManagerTests.swift
  - Sources/Core/Domain/FoodItemMocks.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/FoodForm/FoodFormView.swift
  - README.md
  - Sources/Features/Home/HomeViewModel.swift
  - Tests/FoodEntropyTests/HomeViewModelTests.swift
-->

---
### Requirement: The store location is never specified explicitly once an app group is adopted

The system SHALL let the persistence framework determine the store's location from the app group entitlement alone, and SHALL NOT specify a configuration name, a file URL, or a group container identifier for that purpose.

This constraint exists because the framework's automatic copy of an existing store into the app group container is performed only when it detects the container itself. Naming or addressing the store explicitly bypasses that detection and opens a different, empty store, leaving every existing user's records unreachable at the previous location.

#### Scenario: An app group is introduced to a shipped app

- **WHEN** the app group entitlement is added and no store location is specified in code
- **THEN** the framework moves the existing records into the shared container, and users who upgrade keep their data

#### Scenario: A store location is specified to make the behaviour explicit

- **WHEN** a configuration name, file URL, or container identifier is specified so the location is predictable
- **THEN** an empty store is opened and existing records become unreachable — predictability here is bought with every upgrading user's data, so it SHALL NOT be done

#### Scenario: The automatic copy does not happen

- **WHEN** the copy fails or does not occur
- **THEN** the app continues against the records it can still reach rather than presenting an empty store as success, since sync is off by default and most users have no copy elsewhere


<!-- @trace
source: add-widget
updated: 2026-08-12
code:
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Widget/WidgetStore.swift
  - project.yml
-->

---
### Requirement: The store is reachable by every process that needs it

The system SHALL make the store reachable by both the app and any extension that reads it, by declaring the same app group on each. An extension SHALL open its own connection to that store rather than receiving one from the app.

#### Scenario: An extension reads the records

- **WHEN** an extension needs the current records
- **THEN** it opens the store through the shared app group, because processes cannot reach another process's private container

#### Scenario: An extension fails to open the store

- **WHEN** an extension cannot open or read the store
- **THEN** it presents its empty state and continues, applying the same principle as the app: a read failure yields empty results rather than a crash

<!-- @trace
source: add-widget
updated: 2026-08-12
code:
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Widget/WidgetStore.swift
  - project.yml
-->

---
### Requirement: The store is reachable from a process-level accessor

The system SHALL provide a single process-level accessor for the store within the app process, so that entry points without a connected scene reach the same store connection as the running interface. The app's scene SHALL obtain its store from that accessor rather than constructing its own. The accessor SHALL apply the existing sync preference and the existing layered fallback when it first constructs the store.

Within one app process there SHALL be exactly one such store connection, so that a write made by a scene-less entry point is visible to the interface without reopening the store.

#### Scenario: An action runs before any scene connects

- **WHEN** an assistant action performs while the app has no connected scene
- **THEN** it reaches the store through the process-level accessor and its write succeeds

#### Scenario: A scene-less write is visible to the interface

- **WHEN** an assistant action writes while the app is in the background, and the user then returns to the app
- **THEN** the interface shows the written result without the store being reopened

#### Scenario: The sync preference is honored once per launch

- **WHEN** the accessor constructs the store for the first time in a process
- **THEN** it reads the sync preference at that moment, preserving the rule that a changed preference applies on the next launch

#### Scenario: Store construction still degrades in layers

- **WHEN** the accessor constructs the store and the preferred configuration fails
- **THEN** it falls back through the same layers the app already applies, rather than failing the action

<!-- @trace
source: add-app-intents
updated: 2026-09-13
code:
  - Tests/FoodEntropyTests/FoodItemLookupTests.swift
  - Sources/Core/Intents/IntentSnippetView.swift
  - Tests/FoodEntropyTests/FoodItemActionOutcomeTests.swift
  - Sources/Features/FoodForm/FoodFormMode.swift
  - Sources/Features/FoodForm/FoodFormViewModel+Models.swift
  - Sources/Core/Image/ImageCompressor.swift
  - Sources/Core/Intents/FoodEntropyShortcuts.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Intents/FoodItemActionOutcome.swift
  - CLAUDE.md
  - Sources/App/PendingDeeplink.swift
  - Sources/Core/Components/FoodRowView.swift
  - Tests/FoodEntropyTests/FoodStatusSummaryTests.swift
  - Sources/Core/Ad/AdConfig.swift
  - Sources/Core/Components/StatusChartView.swift
  - Tests/FoodEntropyTests/CurrencyFormatTests.swift
  - Tests/FoodEntropyTests/FoodItemAppEntityTests.swift
  - Tests/FoodEntropyTests/FoodItemActionsTests.swift
  - design/screenshots/README.md
  - Sources/App/SceneDelegate.swift
  - docs/privacy/index.html
  - Tests/FoodEntropyTests/FoodFormViewModelTests.swift
  - project.yml
  - Sources/Core/Intents/FoodItemAppEntity.swift
  - Sources/Core/Extensions/CurrencyFormat.swift
  - docs/index.html
  - README.md
  - Sources/Resources/AppShortcuts.xcstrings
  - Sources/Core/Ad/AdSlotView.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Core/Intents/FoodItemLookup.swift
  - Sources/Core/Intents/FoodItemEntityQuery.swift
  - Sources/Core/Domain/DayBoundary.swift
  - Sources/Core/Store/StoreManager.swift
  - Sources/Core/Intents/FoodItemSpotlightIndex.swift
  - Tests/FoodEntropyTests/HomeViewModelTests.swift
  - Sources/Features/Home/HomeView.swift
  - Sources/Core/Intents/FoodItemSystemIntents.swift
  - design/screenshots/home.png
  - Sources/Features/Settings/SettingsView.swift
  - Sources/Core/Domain/FoodItem.swift
  - Tests/FoodEntropyTests/DeeplinkTests.swift
  - Tests/FoodEntropyTests/StatusChartViewTests.swift
  - Sources/Features/Home/HomeViewModel.swift
  - design/screenshots/settings.png
  - Sources/Core/Domain/FoodItemMocks.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Domain/FoodStatusSummary.swift
  - Sources/Core/Intents/FoodItemIntents.swift
  - Sources/Resources/Localizable.xcstrings
  - design/badges/download-on-the-app-store.svg
  - Sources/Features/Settings/SettingsViewModel.swift
  - Sources/Core/Intents/FoodItemActions.swift
  - Sources/Widget/WidgetStore.swift
  - Tests/FoodEntropyTests/SwiftDataManagerTests.swift
  - design/screenshots/widget.png
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/Widget/FoodEntropyWidget.swift
  - Tests/FoodEntropyTests/DayBoundaryTests.swift
  - Sources/App/Deeplink.swift
  - Sources/Features/FoodForm/FoodFormView.swift
  - design/badges/README.md
  - Sources/Core/Notification/NotificationService.swift
-->
