# widget Specification

## Purpose

TBD - created by archiving change 'add-widget'. Update Purpose after archive.

## Requirements

### Requirement: The widget and the in-app screen share one presentation implementation

The system SHALL render the widget's contents through the same view implementation the home screen uses for its status section, rather than a separate implementation that reproduces the same design. The shared implementation SHALL accept only the values it displays and SHALL NOT read data itself.

#### Scenario: The presentation changes

- **WHEN** the colours, wording, or accessibility handling of the status display is changed
- **THEN** the change appears in both the widget and the home screen, because there is one implementation rather than two

#### Scenario: The container differs between hosts

- **WHEN** the shared implementation is placed in the widget, which has no list context
- **THEN** it renders its contents without a section container, and the section container with its heading remains the home screen's responsibility


<!-- @trace
source: add-widget
updated: 2026-08-12
code:
  - Sources/Widget/FoodEntropyWidget.swift
  - Sources/Widget/WidgetStore.swift
  - Sources/Core/Components/StatusChartView.swift
  - Sources/Core/Domain/FoodStatusSummary.swift
  - Sources/Core/Domain/DayBoundary.swift
-->

---
### Requirement: The widget shows the same status figures as the home screen

The system SHALL display the proportion of items in each expiry bucket, the total count, and each bucket's name and count. It SHALL display the upcoming-expiry amount only when that amount can be computed, and SHALL reserve its space regardless so the layout does not shift.

#### Scenario: Items exist across buckets

- **WHEN** the widget renders with items present
- **THEN** the proportions, total, and per-bucket counts match what the home screen shows for the same data

#### Scenario: No amount can be computed

- **WHEN** no item near expiry carries a recorded cost
- **THEN** the amount line renders nothing rather than showing zero, and the remaining contents stay in the same position

#### Scenario: No items exist

- **WHEN** there are no items to show
- **THEN** the widget shows the same empty-state wording the home screen uses


<!-- @trace
source: add-widget
updated: 2026-08-12
code:
  - Sources/Widget/FoodEntropyWidget.swift
  - Sources/Widget/WidgetStore.swift
  - Sources/Core/Components/StatusChartView.swift
  - Sources/Core/Domain/FoodStatusSummary.swift
  - Sources/Core/Domain/DayBoundary.swift
-->

---
### Requirement: The widget reads data without exposing persisted types

The system SHALL convert every record the widget reads into a domain value before it leaves the reading code, and the timeline entry SHALL carry only displayable values. A persisted model type SHALL NOT appear in a timeline entry.

#### Scenario: A timeline entry is constructed

- **WHEN** the widget prepares an entry for rendering
- **THEN** it carries counts and an optional amount, with no context-bound persistence object among them


<!-- @trace
source: add-widget
updated: 2026-08-12
code:
  - Sources/Widget/FoodEntropyWidget.swift
  - Sources/Widget/WidgetStore.swift
  - Sources/Core/Components/StatusChartView.swift
  - Sources/Core/Domain/FoodStatusSummary.swift
  - Sources/Core/Domain/DayBoundary.swift
-->

---
### Requirement: The widget never terminates on failure

The system SHALL respond to any failure in the widget's data path by rendering the empty state, and SHALL NOT terminate the widget process.

#### Scenario: The store cannot be opened

- **WHEN** the widget cannot open or read the store
- **THEN** it renders the empty state, because a terminated widget shows the user a blank tile, which is worse than showing no items


<!-- @trace
source: add-widget
updated: 2026-08-12
code:
  - Sources/Widget/FoodEntropyWidget.swift
  - Sources/Widget/WidgetStore.swift
  - Sources/Core/Components/StatusChartView.swift
  - Sources/Core/Domain/FoodStatusSummary.swift
  - Sources/Core/Domain/DayBoundary.swift
-->

---
### Requirement: The timeline refreshes at each day boundary and on data change

The system SHALL schedule the widget's next refresh at the start of the following day, and SHALL request a reload when items are added, resolved, or deleted in the app.

#### Scenario: Midnight passes without the app being opened

- **WHEN** the day changes while the app stays closed
- **THEN** the widget's bucket figures reflect the new date, because expiry status is a function of the current date rather than a stored value

#### Scenario: An item is resolved in the app

- **WHEN** a user marks an item used or discarded
- **THEN** the widget's contents update rather than waiting for the next scheduled refresh


<!-- @trace
source: add-widget
updated: 2026-08-12
code:
  - Sources/Widget/FoodEntropyWidget.swift
  - Sources/Widget/WidgetStore.swift
  - Sources/Core/Components/StatusChartView.swift
  - Sources/Core/Domain/FoodStatusSummary.swift
  - Sources/Core/Domain/DayBoundary.swift
-->

---
### Requirement: Tapping the widget opens the app

The system SHALL open the app's home screen when the widget is tapped, and SHALL NOT offer any action that modifies data from within the widget.

#### Scenario: The user taps the widget

- **WHEN** the widget is tapped anywhere
- **THEN** the app opens at the home screen

<!-- @trace
source: add-widget
updated: 2026-08-12
code:
  - Sources/Widget/FoodEntropyWidget.swift
  - Sources/Widget/WidgetStore.swift
  - Sources/Core/Components/StatusChartView.swift
  - Sources/Core/Domain/FoodStatusSummary.swift
  - Sources/Core/Domain/DayBoundary.swift
-->