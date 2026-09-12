# app-intents Specification

## Purpose

TBD - created by archiving change 'add-app-intents'. Update Purpose after archive.

## Requirements

### Requirement: Core food actions run without opening the app

The system SHALL expose adding a food item, marking one consumed, marking one wasted, and extending one's expiry date as actions that complete without bringing the app to the foreground. Each action SHALL delegate to the existing persistence operations rather than reimplementing the write.

#### Scenario: An action runs while the app is not running

- **WHEN** the user runs the "mark consumed" action from Shortcuts while the app is not running
- **THEN** the item's stored status changes to consumed and the app is not brought to the foreground

#### Scenario: An action's result matches in-app behavior

- **WHEN** the user adds a food item through the action with a name and an expiry date
- **THEN** the resulting record is indistinguishable from one created inside the app, including its resolution time being unset and its status being active

#### Scenario: Extending an expiry preserves the other stored values

- **WHEN** the user extends an item's expiry date through the action
- **THEN** the item's name, purchase date, photo, and recorded cost are unchanged

##### Example: extending does not clear the cost

- **GIVEN** an item named "Milk" with expiryDate=2026-09-20, price=89.0, and a stored photo
- **WHEN** the extend action sets expiryDate=2026-09-27
- **THEN** the stored item has expiryDate=2026-09-27, price=89.0, and its photo intact


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

---
### Requirement: Food items are exposed as an app entity with a stable identifier

The system SHALL expose a food item as an assistant-visible entity whose identifier is the item's existing persistent identifier. The entity SHALL carry the item's name, purchase date, expiry date, recorded cost, and its expiry status computed on read. The entity type SHALL NOT hold the persistence model type.

#### Scenario: The entity identifier survives a restart

- **WHEN** an entity identifier captured in one app launch is resolved in a later launch
- **THEN** it resolves to the same food item

#### Scenario: Expiry status is computed, never stored

- **WHEN** the entity reports an item's expiry status
- **THEN** the value is derived from the expiry date against the current date, and no expiry status is persisted


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

---
### Requirement: Entity queries resolve by identifier, by name, and by suggestion

The system SHALL resolve entities by identifier, SHALL filter entities by a name string supplied by the caller, and SHALL offer the currently active items as suggestions when no criteria are supplied.

#### Scenario: Resolving a deleted item

- **WHEN** a query resolves an identifier whose item has been deleted
- **THEN** the query returns no entity for that identifier

#### Scenario: Suggestions exclude resolved items

- **WHEN** the system asks for suggested entities
- **THEN** only items whose stored status is active are offered

##### Example: name filtering is case-insensitive and partial

| Stored items | Filter string | Result |
| ------------ | ------------- | ------ |
| Milk, Milk Chocolate, Bread | "milk" | Milk, Milk Chocolate |
| Milk, Bread | "MILK" | Milk |
| Milk, Bread | "cheese" | (none) |


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

---
### Requirement: Opening a food item presents that item

The system SHALL expose an open action that takes one food item and presents that item's detail, not merely the app. The action SHALL be available on every supported version, and SHALL reach its destination through the centralized deeplink rather than navigating on its own.

This action is also what the system invokes when a person taps a food item in Spotlight, so both routes SHALL arrive at the same destination.

The system SHALL NOT claim in-app search as an assistant capability. Finding food items is exposed as an ordinary action that returns its matches; it carries no schema, so the assistant reaches it only through the app's stated phrases, not through free-form search requests.

#### Scenario: Opening an item by voice

- **WHEN** the user asks the assistant to open a named food item
- **THEN** the app comes to the foreground showing that item's detail

#### Scenario: Tapping a food item in Spotlight

- **WHEN** the user taps a food item among Spotlight's results
- **THEN** the app comes to the foreground showing that item's detail

#### Scenario: Finding items returns matches rather than presenting them

- **WHEN** the find action runs with a name fragment
- **THEN** it returns the matching active items as values to its caller, and the app is not brought to the foreground

#### Scenario: Running on iOS 26

- **WHEN** the app runs on iOS 26
- **THEN** every action including the open action is available, without any error or degraded-mode message


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

---
### Requirement: Food items are indexed for Spotlight

The system SHALL index active food items so they are findable in Spotlight by name, and SHALL keep that index current whenever stored data changes.

#### Scenario: A newly added item becomes findable

- **WHEN** a food item is added by any path
- **THEN** it becomes findable in Spotlight by its name

#### Scenario: A resolved item stops being offered

- **WHEN** an item is marked consumed, marked wasted, or deleted
- **THEN** it is no longer offered as an active food item in Spotlight


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

---
### Requirement: On-screen food items are annotated for assistant resolution

The system SHALL annotate each food row on the home list with its entity identifier, so that an assistant capable of reading the screen can resolve a reference to what the user is looking at. The annotation SHALL NOT change any visual presentation, and SHALL NOT delay the system's request for the on-screen payload.

Whether the assistant actually resolves such a reference is outside this project's control and SHALL NOT be treated as an acceptance criterion: the capability reaches users only on a supported device, in a supported language, and in a supported region, and it was unavailable for this project's primary audience when the annotation shipped. The requirement covers only what the app provides.

#### Scenario: Annotation is attached to food rows only

- **WHEN** the home list renders its summary chart, its waste statistics, and its food rows
- **THEN** only the food rows carry an entity identifier, because rows that represent no food item cannot supply one and delay the payload request until it times out

#### Scenario: The payload request completes within the system deadline

- **WHEN** the system requests the on-screen entity payload for a visible list of food rows
- **THEN** each row resolves without loading its stored photo, so the request completes before the deadline

#### Scenario: Annotation has no visual effect

- **WHEN** the home list renders with annotations present
- **THEN** its layout and appearance are identical to the unannotated rendering


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

---
### Requirement: Actions that do not open the app report their result

Every action that completes without bringing the app to the foreground SHALL report what it did, both as spoken dialog and as a visual snippet. The spoken dialog SHALL be a complete sentence on its own, because a voice-only device receives the dialog and never the snippet.

The snippet SHALL identify the food item by name and SHALL state the resulting condition: an item that left the list SHALL NOT show a remaining-days figure, and an item still in the list SHALL show its expiry date. The report SHALL be built from values the action already holds, without an additional read of stored data.

A query action that returns its matches as values SHALL NOT provide dialog, because its result is the returned value itself.

#### Scenario: Marking an item used without opening the app

- **WHEN** the user marks a food item as used through the assistant
- **THEN** the assistant speaks a sentence naming that item, and shows a snippet naming it and stating that it left the list

#### Scenario: Extending an expiry reports the new date

- **WHEN** the user extends a food item's expiry date
- **THEN** the snippet shows the new expiry date, not the previous one

#### Scenario: A voice-only device receives a complete sentence

- **WHEN** an action runs on a device that can speak but not display
- **THEN** the spoken dialog alone conveys which item changed and how

#### Scenario: Finding items stays silent

- **WHEN** the find action returns its matches
- **THEN** no dialog is spoken, because the returned values are the result


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

---
### Requirement: Assistant phrases and action titles are localized

The system SHALL route every user-visible action title, parameter summary, and spoken phrase through the string catalog, with English as the source language and a Traditional Chinese translation present for each. Each spoken phrase SHALL include the application name token.

#### Scenario: Phrases exist for both languages

- **WHEN** the shortcut phrases are collected for English and for Traditional Chinese
- **THEN** each language has at least one phrase per exposed action

#### Scenario: No hardcoded user-visible string

- **WHEN** the string catalog is inspected after a build
- **THEN** it contains no stale entries and no entry missing its Traditional Chinese translation


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

---
### Requirement: Actions fail loudly when the target no longer exists

The system SHALL surface an error when an action names a food item that no longer exists or has already left the active list, rather than reporting success. The error message SHALL be localized.

The system SHALL likewise surface a localized error when the change cannot be stored, and SHALL NOT speak or display a confirmation in that case. Reporting success for a change that was not stored is worse here than in the app's own interface: the app shows an unchanged list, whereas an assistant states that the change was made.

#### Scenario: Acting on a deleted item

- **WHEN** an action targets a food item that has been deleted
- **THEN** the action reports a localized error and no write occurs

#### Scenario: Acting on an already-resolved item

- **WHEN** an action marks an item consumed that was already marked wasted
- **THEN** the action reports a localized error rather than silently succeeding

#### Scenario: The change cannot be stored

- **WHEN** an action's write fails
- **THEN** the action reports a localized error, and no confirmation is spoken or displayed

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