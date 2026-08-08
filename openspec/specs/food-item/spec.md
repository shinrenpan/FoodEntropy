# food-item Specification

## Purpose

The food item domain model and its two independent status axes. `RecordStatus` is stored and changes only when the user acts; `ExpiryStatus` is derived on every read and must never reach a `@Model` — persisting it would silently freeze every item's colour and bucket at whatever day it was written. The expiry day itself is deliberately `nearExpiry` rather than `expired`, because most food is still edible on its date and the reminder fires that same morning; marking it red would have the app contradict its own notification and push the user toward the waste it exists to prevent.

## Requirements

### Requirement: A food item carries a stored record status and a derived expiry status

The system SHALL model a food item with a stored `RecordStatus` of `active`, `consumed`, or `wasted`, and SHALL derive its `ExpiryStatus` of `fresh`, `nearExpiry`, or `expired` from the item's expiry date at the moment of reading. The derived expiry status SHALL NOT be persisted in any form.

#### Scenario: Expiry status changes across midnight without any write

- **WHEN** an item is one day away from expiry, and the app is reopened after midnight with no data modified
- **THEN** the item reports the expiry status for its new day count, without any record having been written

#### Scenario: Record status only changes when the user acts

- **WHEN** days pass and an item becomes expired
- **THEN** its record status remains `active` until the user marks it consumed, marks it wasted, or deletes it

---



<!-- @trace
source: baseline-food-item
updated: 2026-08-08
code:
  - Sources/Core/Domain/FoodItem.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
-->

---
### Requirement: Expiry is measured in calendar days in the device's time zone

The system SHALL compute days-until-expiry by taking the start of day, in the device's current calendar and time zone, for both today and the expiry date, and then taking the difference in days. The time of day at which an item was recorded SHALL NOT affect the result.

#### Scenario: Two items recorded at different times of day agree

- **WHEN** one item is recorded in the morning and another late at night, both with tomorrow's date as the expiry date
- **THEN** both report the same number of days until expiry

#### Scenario: An expired item reports a negative day count

- **WHEN** an item's expiry date is before today
- **THEN** the days-until-expiry value is negative

---



<!-- @trace
source: baseline-food-item
updated: 2026-08-08
code:
  - Sources/Core/Domain/FoodItem.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
-->

---
### Requirement: The expiry day itself counts as near-expiry, not expired

The system SHALL classify an item as `expired` only when its days-until-expiry is negative, SHALL classify it as `nearExpiry` when that value is between zero and the near-expiry window threshold inclusive, and SHALL classify it as `fresh` beyond that threshold. The threshold SHALL be a single named constant.

#### Scenario: An item expiring today is near-expiry

- **WHEN** an item's expiry date is today
- **THEN** its expiry status is `nearExpiry`, not `expired`, so it is not presented as waste on the day it is still edible

#### Scenario: An item becomes expired the day after its expiry date

- **WHEN** an item's expiry date was yesterday
- **THEN** its expiry status is `expired`

#### Scenario: The far edge of the near-expiry window is inclusive

- **WHEN** an item's expiry date is exactly the threshold number of days away
- **THEN** its expiry status is `nearExpiry`; one day further out it is `fresh`

---



<!-- @trace
source: baseline-food-item
updated: 2026-08-08
code:
  - Sources/Core/Domain/FoodItem.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
-->

---
### Requirement: Expiry evaluation is a pure function with injectable today and calendar

The system SHALL expose days-until-expiry and expiry-status evaluation as pure functions that accept the reference date and calendar as parameters with defaults, and any convenience accessor on the item SHALL delegate to them rather than reimplementing the rule.

#### Scenario: A boundary case is tested deterministically

- **WHEN** a test evaluates an item's expiry status against an injected reference date
- **THEN** the result depends only on the injected date and calendar, so midnight, month-end, and leap-day boundaries can be asserted without waiting for real time to pass

---



<!-- @trace
source: baseline-food-item
updated: 2026-08-08
code:
  - Sources/Core/Domain/FoodItem.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
-->

---
### Requirement: An item leaves the active list through one of four exits

The system SHALL support exactly four exits from the active list: extending the expiry date, which keeps the record `active`; marking consumed, which sets the record to `consumed`; marking wasted, which sets it to `wasted`; and deleting, which removes the record entirely. Marking consumed or wasted SHALL record the time at which the item was resolved.

#### Scenario: Extending keeps the item in the list

- **WHEN** the user extends an item's expiry date
- **THEN** the item stays in the active list with its record status unchanged, re-sorted and re-classified according to its new expiry date

#### Scenario: Consumed and wasted items remain available as history

- **WHEN** the user marks an item consumed or wasted
- **THEN** the item disappears from the active list but its record is retained with a resolution time, so it can contribute to waste statistics

#### Scenario: Deleting leaves no trace

- **WHEN** the user deletes an item, having added it by mistake
- **THEN** no record of it remains, and it contributes to neither the active list nor waste statistics


<!-- @trace
source: baseline-food-item
updated: 2026-08-08
code:
  - Sources/Core/Domain/FoodItem.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
-->

---
### Requirement: A food item may carry an optional recorded cost

The system SHALL allow a food item to carry an optional cost representing the total amount spent on that record, not a unit price. An item without a recorded cost SHALL behave exactly as before in every other respect.

#### Scenario: Recording an item without a cost

- **WHEN** the user records a food item and leaves the cost unset
- **THEN** the item is stored and behaves identically to items recorded before costs existed, participating normally in bucketing, sorting, and reminders

#### Scenario: One record means one purchase

- **WHEN** the user buys three cartons of milk and records them as a single item
- **THEN** the cost they enter represents the whole purchase, since there is no quantity to multiply by

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