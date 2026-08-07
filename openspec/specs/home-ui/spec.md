# home-ui Specification

## Purpose

The app's only list screen and the only place the user acts. v1.0.0 merged the former analytics tab into it — the two listed the same active items in different orders — so the overview and the means to act on it now sit on one screen. Two details here look like bugs and are not: the delete swipe deliberately avoids SwiftUI's destructive role, because that role removes the row the instant it is tapped while this screen must first ask for confirmation (cancel would then leave the item stored but missing from the list until the next refresh); and the clear-history control keys off all-time history while the statistics show only a rolling window, so history older than the window never becomes unreachable.

## Requirements

### Requirement: The home screen carries both the current overview and the working list

The system SHALL present, on a single screen from top to bottom, the ad slot pinned above the list, a current-status chart, waste statistics, three expiry buckets, and an add button pinned across the bottom. There SHALL NOT be a separate analytics screen.

#### Scenario: Acting on what the overview reveals

- **WHEN** the user opens the app and sees from the chart that items have expired
- **THEN** the expired items are on the same screen, ready to be acted on without navigating elsewhere

#### Scenario: Adding an item is always reachable

- **WHEN** the user has scrolled anywhere in the list
- **THEN** the add button remains visible at the bottom of the screen

---



<!-- @trace
source: baseline-home-ui
updated: 2026-08-08
code:
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Components/FoodRowView.swift
-->

---
### Requirement: Items are grouped into three expiry buckets, most urgent first, and empty buckets still appear

The system SHALL group active items into expired, near-expiry, and fresh buckets in that order, SHALL label each bucket header with its name and count, SHALL render a bucket even when it holds no items, and SHALL keep each bucket in the order the data layer supplied.

#### Scenario: Nothing has expired

- **WHEN** the user has no expired items
- **THEN** the expired bucket is still shown, with a count of zero, so the user can confirm at a glance that nothing is overdue

#### Scenario: Items within a bucket are ordered by urgency

- **WHEN** a bucket holds several items
- **THEN** they appear in the order the data layer returned, soonest expiry first, without the screen re-sorting them

---



<!-- @trace
source: baseline-home-ui
updated: 2026-08-08
code:
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Components/FoodRowView.swift
-->

---
### Requirement: The status chart is legible without relying on colour

The system SHALL accompany the status chart with a legend pairing each colour with its bucket name and count, SHALL show the total number of active items at the centre of the chart, and SHALL show an empty-state message when there are no active items.

#### Scenario: A user who cannot distinguish the colours

- **WHEN** a user with colour vision deficiency views the chart
- **THEN** each segment is identifiable from the legend's name and count rather than from its colour alone

#### Scenario: No items recorded yet

- **WHEN** the user has no active items
- **THEN** the chart area shows an empty-state message instead of an empty or misleading chart

---



<!-- @trace
source: baseline-home-ui
updated: 2026-08-08
code:
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Components/FoodRowView.swift
-->

---
### Requirement: Waste statistics cover a rolling recent window and distinguish no data from zero

The system SHALL calculate the waste rate as wasted over the sum of consumed and wasted, counting only items resolved within a rolling window of recent days defined by a named constant, and SHALL show an empty-state message rather than a zero percentage when no items were resolved in that window.

#### Scenario: Recent behaviour is what shows

- **WHEN** the user wasted several items months ago but has wasted none recently
- **THEN** the displayed rate reflects only the recent window, so an improvement is visible

#### Scenario: No resolved items in the window

- **WHEN** no item has been consumed or wasted within the window
- **THEN** the section shows an empty-state message, not a rate of zero

---



<!-- @trace
source: baseline-home-ui
updated: 2026-08-08
code:
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Components/FoodRowView.swift
-->

---
### Requirement: Clearing history is offered whenever any history exists at all

The system SHALL show the clear-history control in the waste statistics header whenever any resolved record exists, regardless of the statistics window, SHALL require confirmation before clearing, and SHALL clear all resolved records and refresh the screen when confirmed.

#### Scenario: Old history outside the window can still be cleared

- **WHEN** the user's only resolved records are older than the statistics window
- **THEN** the statistics show the empty-state message, and the clear control is still offered so the stored history is not unreachable

#### Scenario: Clearing empties the statistics

- **WHEN** the user confirms clearing history
- **THEN** all resolved records are removed, the statistics return to their empty state, and the clear control disappears

---



<!-- @trace
source: baseline-home-ui
updated: 2026-08-08
code:
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Components/FoodRowView.swift
-->

---
### Requirement: Each row offers four distinct actions across separate gestures

The system SHALL mark an item consumed on a swipe in one direction, SHALL offer deletion on a swipe in the other, SHALL open the edit screen on a tap, and SHALL offer extending the expiry date, marking consumed, and marking wasted in a long-press menu. The long-press menu SHALL NOT offer deletion or editing, so the only paths to a destructive or navigating action stay the swipe and the tap.

#### Scenario: Marking an item consumed

- **WHEN** the user swipes a row toward marking it consumed
- **THEN** the item leaves the list immediately, with no confirmation

#### Scenario: The long-press menu covers the non-destructive actions

- **WHEN** the user long-presses a row
- **THEN** the menu offers extending the expiry date, marking consumed, and marking wasted, and offers neither deletion nor editing

#### Scenario: Extending stays on the home screen

- **WHEN** the user extends an item's expiry date
- **THEN** a date selection appears, the new date is saved on confirmation, and the user remains on the home screen with the item re-bucketed

---



<!-- @trace
source: baseline-home-ui
updated: 2026-08-08
code:
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Components/FoodRowView.swift
-->

---
### Requirement: Only deletion asks for confirmation, and the row stays until the user answers

The system SHALL require confirmation only for deletion among the four row actions, and SHALL keep the row present in the list from the moment the delete control is tapped until the user confirms. Cancelling SHALL leave the item unchanged and still listed.

#### Scenario: Cancelling a deletion leaves the row in place

- **WHEN** the user taps delete on a row and then cancels the confirmation
- **THEN** the row is still in the list in its original position, without waiting for any refresh

#### Scenario: Confirming a deletion removes the item

- **WHEN** the user confirms the deletion
- **THEN** the item is removed permanently and does not appear in waste statistics

#### Scenario: Non-destructive actions do not interrupt

- **WHEN** the user marks an item consumed or wasted, or extends its date
- **THEN** the action takes effect immediately with no confirmation step

---



<!-- @trace
source: baseline-home-ui
updated: 2026-08-08
code:
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Components/FoodRowView.swift
-->

---
### Requirement: The screen reloads on appearing and reconciles reminders after data changes

The system SHALL reload its data when the screen appears, and SHALL, after any action that changes the active list, reload and then reconcile notification scheduling. Clearing history SHALL reload without reconciling.

#### Scenario: Returning from editing shows the change

- **WHEN** the user edits an item and returns to the home screen
- **THEN** the list, buckets, and chart reflect the edit

#### Scenario: Resolving an item updates its reminder

- **WHEN** the user marks an item consumed from the list
- **THEN** the list refreshes and notification scheduling is reconciled so the item's reminder is dropped

#### Scenario: Clearing history leaves reminders untouched

- **WHEN** the user clears history
- **THEN** the statistics refresh, and reminders for active items are unaffected

---



<!-- @trace
source: baseline-home-ui
updated: 2026-08-08
code:
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Components/FoodRowView.swift
-->

---
### Requirement: A hint describes the gestures that are not otherwise discoverable

The system SHALL display, in the footer of the last bucket, a hint describing the tap, swipe, and long-press actions available on a row.

#### Scenario: Discovering the long-press menu

- **WHEN** the user scrolls to the end of the list
- **THEN** a hint explains that tapping edits, swiping marks consumed or deletes, and long-pressing offers extending or marking wasted


<!-- @trace
source: baseline-home-ui
updated: 2026-08-08
code:
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Core/Components/FoodRowView.swift
-->