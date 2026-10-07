# home-ui Specification

## Purpose

The app's dashboard: a stack of five cards — current status, waste statistics, and one per expiry bucket — of which exactly one is fully shown at a time. v1.0.0 merged the former analytics tab into it; the food rows then moved out of it, into a list presented from a bucket's card, because holding both the overview and the working list crowded the screen and left the first food row below the fold. Two details here look like bugs and are not: the delete swipe deliberately avoids SwiftUI's destructive role, because that role removes the row the instant it is tapped while this screen must first ask for confirmation (cancel would then leave the item stored but missing from the list until the next refresh); and the clear-history control keys off all-time history while the statistics show only a rolling window, so history older than the window never becomes unreachable.

## Requirements

### Requirement: Items are grouped into three expiry buckets, most urgent first, and empty buckets still appear

The system SHALL group active items into expired, near-expiry, and fresh buckets, SHALL give each bucket a card labelled with its name and count, SHALL present a bucket's card even when it holds no items, and SHALL keep each bucket in the order the data layer supplied.

The cards SHALL be ordered by urgency — expired, then near-expiry, then fresh — except that whichever card is fully in view is placed last in the stack so nothing overlaps it.

#### Scenario: Nothing has expired

- **WHEN** the user has no expired items
- **THEN** the expired bucket's card is still shown, with a count of zero, so the user can confirm at a glance that nothing is overdue

#### Scenario: Items within a bucket are ordered by urgency

- **WHEN** a bucket's list is opened and it holds several items
- **THEN** they appear in the order the data layer returned, soonest expiry first, without the screen re-sorting them

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

These actions SHALL be available wherever food rows are shown. Since the home screen shows no rows, they are offered in a bucket's list.

#### Scenario: Marking an item consumed

- **WHEN** the user swipes a row toward marking it consumed
- **THEN** the item leaves the list immediately, with no confirmation

#### Scenario: The long-press menu covers the non-destructive actions

- **WHEN** the user long-presses a row
- **THEN** the menu offers extending the expiry date, marking consumed, and marking wasted, and offers neither deletion nor editing

#### Scenario: Extending stays in the list

- **WHEN** the user extends an item's expiry date
- **THEN** a date selection appears, the new date is saved on confirmation, and the user remains in the list with the item removed from that bucket if it no longer belongs there

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

The system SHALL reload its data when the home screen appears, and SHALL, after any action that changes the active list, reload and then reconcile notification scheduling. Clearing history SHALL reload without reconciling.

A bucket's list SHALL reflect an action taken within it without being reopened, and the home screen's cards SHALL reflect those actions once that list is closed.

#### Scenario: Returning from editing shows the change

- **WHEN** the user edits an item and returns to the list it was opened from
- **THEN** that list reflects the edit, and so do the home screen's cards once the list is closed

#### Scenario: Resolving an item updates its reminder

- **WHEN** the user marks an item consumed from a bucket's list
- **THEN** the list refreshes and notification scheduling is reconciled so the item's reminder is dropped

#### Scenario: Clearing history leaves reminders untouched

- **WHEN** the user clears history
- **THEN** the statistics refresh, and reminders for active items are unaffected

---
### Requirement: A hint describes the gestures that are not otherwise discoverable

The system SHALL display a hint describing the tap, swipe, and long-press actions available on a row, positioned where those rows are shown.

#### Scenario: Discovering the long-press menu

- **WHEN** the user opens a bucket's list and reaches the end of it
- **THEN** a hint explains that tapping edits, swiping marks consumed or deletes, and long-pressing offers extending or marking wasted

---
### Requirement: The amount about to expire is surfaced while the food can still be saved

The system SHALL display the total recorded cost of active items whose expiry status is near-expiry, SHALL phrase it as a lower bound rather than an exact figure, and SHALL format the currency according to the device's region. Items that are already expired or still fresh SHALL NOT contribute to this amount.

#### Scenario: Money is named while there is still time to act

- **WHEN** the user has near-expiry items with recorded costs
- **THEN** the home screen shows the summed amount phrased as a lower bound, so the user learns what is at stake while the food can still be eaten

#### Scenario: The figure never claims to be complete

- **WHEN** only some near-expiry items have recorded costs
- **THEN** the amount is still phrased as a lower bound, and the wording does not change based on how many items have costs

#### Scenario: Fresh stock is not counted

- **WHEN** the user has expensive items that are still well within their expiry dates
- **THEN** they do not contribute to the amount, which reports only what is at risk rather than the value of everything stored

#### Scenario: Already-expired items are excluded

- **WHEN** the user has expired items carrying recorded costs
- **THEN** they do not contribute to this amount, which speaks only to what can still be saved


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
### Requirement: The upcoming amount disappears rather than reporting zero

The system SHALL omit the upcoming-expiry amount entirely when no near-expiry item carries a recorded cost, and SHALL NOT display a zero amount or a prompt encouraging the user to record costs.

#### Scenario: A user who records no costs sees no amount

- **WHEN** the user has never entered a cost
- **THEN** the home screen looks as it did before this feature existed, with no zero figure and no prompt occupying space

#### Scenario: No near-expiry items at all

- **WHEN** nothing is currently near expiry
- **THEN** no amount is shown


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
### Requirement: Discarded cost appears as secondary information in waste statistics

The system SHALL show the total recorded cost of items wasted within the statistics window as secondary information within the waste statistics section, SHALL keep the waste percentage as that section's primary figure, and SHALL use the same rolling window as the existing statistics.

#### Scenario: The discarded amount does not become the headline

- **WHEN** the user views waste statistics with some wasted items carrying costs
- **THEN** the waste percentage remains the section's main figure and the amount appears alongside it as supporting detail, so a small amount cannot read as reassurance

#### Scenario: The discarded amount follows the same window as the percentage

- **WHEN** an item was wasted before the start of the statistics window
- **THEN** its cost is excluded from the amount, consistently with how it is already excluded from the percentage

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
### Requirement: Settings is reached from the home screen's navigation bar

The system SHALL offer a settings control in the trailing position of the home screen's navigation bar whenever settings is not already visible beside the home screen, and SHALL open settings as a pushed screen that returns by the standard back control and the interactive back gesture. The control SHALL carry a settings label drawn from the String Catalog so it is named rather than icon-only in every language. While the two-column layout shows settings in the leading column, the control SHALL NOT be shown.

The home screen SHALL emit this navigation as an intent for its host to execute, in the same way it emits opening the add and edit forms, rather than presenting settings itself.

#### Scenario: Opening settings from the home screen

- **WHEN** the user taps the settings control in the home screen's navigation bar
- **THEN** the settings screen is pushed onto the same stack, showing a back control that returns to the home screen

#### Scenario: Returning from settings

- **WHEN** the user leaves settings by the back control or the back gesture
- **THEN** the home screen is revealed and reloads, so a preference changed in settings is reflected without relaunching

#### Scenario: A deeplink arriving while settings is open

- **WHEN** a food item deeplink arrives while the user is on the settings screen
- **THEN** settings is removed from the stack and the item's form is shown, rather than the form appearing on top of settings or the stack coming to rest on the home screen

#### Scenario: No settings control while settings is beside the home screen

- **WHEN** the two-column layout is showing settings in the leading column
- **THEN** the home screen's navigation bar shows no settings control, and the control returns as soon as the layout goes back to one column


<!-- @trace
source: adapt-iphone-duo
updated: 2026-10-07
code:
  - Sources/Features/Home/SideBySideLayout.swift
  - Sources/Features/Home/HomeRootView.swift
  - Sources/Core/Store/StoreManager.swift
  - Sources/Features/Home/HomeHostController.swift
  - Tests/FoodEntropyTests/SideBySideLayoutTests.swift
  - CLAUDE.md
  - project.yml
  - Sources/Core/Ad/BannerAdView.swift
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Settings/SettingsView.swift
  - Sources/Features/Settings/SettingsHostController.swift
  - Tests/FoodEntropyTests/StoreManagerTests.swift
  - Tests/FoodEntropyTests/BannerAdViewTests.swift
-->

---
### Requirement: The home screen is a stack of cards and the working list sits behind one of them

The system SHALL present the home screen as a single stack of five cards — current status, waste statistics, and one card per expiry bucket — with the ad slot pinned above the stack and an add button pinned across the bottom. Exactly one card SHALL be fully shown at a time; the others SHALL show only their leading edge, carrying enough for the user to choose between them. There SHALL NOT be a separate analytics screen.

The home screen SHALL NOT display individual food rows. The working list of a bucket SHALL be reached from that bucket's card.

#### Scenario: Choosing what to look at

- **WHEN** the user opens the app
- **THEN** all five cards are visible at once, each showing at least its name and its headline figure, so the user can pick one without scrolling

#### Scenario: Adding an item is always reachable

- **WHEN** the user has scrolled anywhere on the home screen
- **THEN** the add button remains visible at the bottom of the screen

---
### Requirement: Tapping a card brings it forward, and a second tap opens that bucket's list

The system SHALL bring a card fully into view when it is tapped, without presenting anything over the home screen. When a card that is already fully in view represents a bucket that holds items, a further tap SHALL open that bucket's list. A card representing a summary, or a bucket holding no items, SHALL NOT open anything however many times it is tapped.

A bucket card that a further tap would open SHALL carry a visible indicator of that, so the second tap is not a hidden interaction. No other card SHALL carry that indicator.

Once the user has chosen a card, that choice SHALL survive every subsequent reload — returning to the home screen, the app coming to the foreground, or the data changing underneath. The system SHALL choose a card on the user's behalf only before they have chosen one themselves, and SHALL then choose the most urgent bucket that holds items. A bucket that holds nothing is a legitimate choice: the user asked to look at it, and reloading SHALL NOT take it away from them.

#### Scenario: Browsing the cards without being interrupted

- **WHEN** the user taps through several cards in turn
- **THEN** each comes forward in place and nothing is presented over the screen, so the user can compare them

#### Scenario: Opening a bucket's list

- **WHEN** the user taps a bucket card that is already fully in view and holds items
- **THEN** that bucket's list opens

#### Scenario: A summary card never opens a list

- **WHEN** the user taps the current-status or waste-statistics card repeatedly
- **THEN** it stays fully in view and nothing opens, and it never showed an indicator suggesting otherwise

#### Scenario: An empty bucket does not open

- **WHEN** the user taps a bucket card holding no items, twice
- **THEN** it comes forward and nothing opens

#### Scenario: The first card is chosen by urgency

- **WHEN** the user opens the app and has not yet tapped any card
- **THEN** the most urgent bucket holding items is the one fully in view

#### Scenario: A chosen card survives leaving and returning

- **WHEN** the user brings a card forward, goes to settings, and comes back
- **THEN** the same card is still fully in view

#### Scenario: A chosen empty bucket is not taken away

- **WHEN** the user brings forward a bucket that holds nothing, and the screen then reloads for any reason
- **THEN** that bucket's card is still the one fully in view

#### Scenario: A chosen bucket that empties stays chosen

- **WHEN** the user resolves the last item in the bucket they are looking at
- **THEN** that bucket's card remains fully in view, now stating that it holds no items


<!-- @trace
source: show-row-price-and-keep-card-selection
updated: 2026-09-16
code:
  - Tests/FoodEntropyTests/HomeViewModelTests.swift
  - Sources/Core/Components/FoodRowView.swift
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Features/Home/HomeViewModel.swift
-->

---
### Requirement: A bucket card states an amount, or the soonest expiry when no amount is recorded

The system SHALL show, on a fully visible bucket card, the total recorded cost of that bucket's items together with when its soonest item expires. When no item in that bucket carries a recorded cost, the expiry timing SHALL become the card's headline instead, and the card SHALL NOT display a zero amount or a prompt encouraging the user to record costs.

The expiry timing SHALL be taken from the first item the data layer supplied for that bucket, which is the soonest to expire, or — for the expired bucket — the one overdue longest.

Every bucket card SHALL occupy the same height when fully in view, whether or not it has an amount to show, so that moving between buckets does not shift the stack.

#### Scenario: A bucket with recorded costs

- **WHEN** the user brings forward a bucket whose items carry recorded costs
- **THEN** the card names the total and also says when the soonest of them expires

#### Scenario: A bucket with no recorded costs

- **WHEN** the user brings forward a bucket in which no item has a recorded cost
- **THEN** the card names when the soonest item expires, shows no amount, and offers no prompt about recording costs

#### Scenario: Moving between buckets does not shift the stack

- **WHEN** the user brings forward one bucket and then another, one having recorded costs and the other not
- **THEN** the stack occupies the same height in both cases

---
### Requirement: A food row states its recorded cost, and shows nothing when none was recorded

The system SHALL display a food item's recorded cost on its row, formatted for the device's region, positioned as trailing secondary information so it does not compete with the item's name or its expiry timing.

A row for an item carrying no recorded cost SHALL display no amount, no zero, and no placeholder in its place. Cost is an optional field, and a row that never had one must not imply it is worth nothing.

#### Scenario: A row for an item with a recorded cost

- **WHEN** the user opens a bucket's list containing an item whose cost was recorded
- **THEN** the row shows that amount alongside the item's name and expiry timing

#### Scenario: A row for an item with no recorded cost

- **WHEN** a bucket's list contains an item whose cost was never recorded
- **THEN** that row shows no amount and nothing standing in for one, while rows that do have amounts still show theirs

#### Scenario: The row's actions are unaffected

- **WHEN** the user taps, swipes, or long-presses a row that shows an amount
- **THEN** the same four actions behave exactly as they do on a row without one

<!-- @trace
source: show-row-price-and-keep-card-selection
updated: 2026-09-16
code:
  - Tests/FoodEntropyTests/HomeViewModelTests.swift
  - Sources/Core/Components/FoodRowView.swift
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - Sources/Features/Home/HomeViewModel.swift
-->

---
### Requirement: Colour on the card stack carries urgency and nothing else

The system SHALL colour a bucket card by the expiry status it represents, and SHALL give every card that represents a summary rather than a bucket a surface carrying no hue at all. A summary card's surface SHALL be the same in every colour scheme, so that it never approaches the colour of the screen behind it.

Every card SHALL be legible on its own surface: the system SHALL NOT place a separate background behind a card's contents in order to make them readable.

Adjacent cards in the stack SHALL be distinguishable from each other in every colour scheme, including where one card overlaps the one behind it.

#### Scenario: A summary card is not mistaken for a bucket

- **WHEN** the user looks at the stack
- **THEN** only the three bucket cards carry colour, and the colour each one carries is the one already used for that expiry status elsewhere in the app

#### Scenario: The stack reads as cards on a dark screen

- **WHEN** the user views the home screen in a dark colour scheme
- **THEN** every card, summary cards included, is distinguishable from the screen behind it and from the card it overlaps

#### Scenario: A summary card's contents stay readable in a light colour scheme

- **WHEN** the user brings forward the current-status or waste-statistics card while the device is in a light colour scheme
- **THEN** the chart, its legend, the waste rate and its counts are all readable, and none of them sits on a background of its own

<!-- @trace
source: restyle-card-surfaces
updated: 2026-09-16
code:
  - README.md
  - project.yml
  - Sources/Features/Home/HomeView.swift
-->

---
### Requirement: A wide container shows settings beside the home screen

When the space the home screen is given is wider than it is tall, the system SHALL show two columns: settings in the leading column and the home screen (card stack, ad slot, add button) in the trailing column. When the space is not wider than it is tall, the system SHALL show the home screen alone, exactly as on a regular iPhone. On the devices this app supports, only the inner display of an iPhone Duo held in landscape produces a wide space; regular iPhones and the Duo outer display stay portrait (see `app-shell`).

The home screen SHALL keep its identity when the second column appears or disappears, so its scroll position, its open sheets, and its loaded state survive folding, unfolding, and rotation rather than being rebuilt.

The boundary between the columns SHALL follow the device's fold as reported by the system's division region:

- while the device is partially folded (the division region is active), each column SHALL end at its side of the fold and the fold's width SHALL be left empty between them;
- while the device lies flat (the division region is inactive), the boundary SHALL sit at the centre of the fold rather than at half the container's width.

The empty space left for the fold SHALL match the columns' background rather than showing the window's background.

#### Scenario: Holding the inner display in landscape

- **WHEN** an iPhone Duo is fully unfolded and held in landscape with the app on the home screen
- **THEN** settings is shown in the leading column and the home screen in the trailing column

#### Scenario: Partially folding keeps both columns off the fold

- **WHEN** the unfolded iPhone Duo is partially folded while showing both columns
- **THEN** each column ends at its side of the fold and nothing is drawn across it, at every fold angle short of flat

##### Example: Measured column widths on iPhone Duo

| Pose | Leading | Gap | Trailing | Notes |
| ---- | ------- | --- | -------- | ----- |
| Flat, landscape | 475 | 0 | 391 | container 867×553 pt, division 455–495 inactive |
| Partially folded, landscape | 455 | 40 | 371 | division 455–495 active; same at every bend angle |

Values measured in the iPhone Duo simulator (Xcode 27.1 RC, iOS 27.1) on 2026-10-07. The trailing widths 391 and 371 are on-screen readings truncated to whole points; the arithmetic values are 392 (867 − 475) and 372 (867 − 495), and tests assert the arithmetic values.

#### Scenario: Unfolding and folding do not jump the boundary

- **WHEN** the device moves between partially folded and flat while showing both columns
- **THEN** the boundary stays at the fold and each column changes only by its half of the fold's width

#### Scenario: Narrow space shows the home screen alone

- **WHEN** the app runs on a regular iPhone, on the iPhone Duo outer display, or on the inner display held in portrait
- **THEN** only the home screen is shown and no settings column appears

#### Scenario: Changing between one and two columns keeps the home screen

- **WHEN** the device is rotated or unfolded so that the layout changes between one and two columns
- **THEN** the home screen keeps its position in the card stack and any sheet it presented remains open


<!-- @trace
source: adapt-iphone-duo
updated: 2026-10-07
code:
  - Sources/Features/Home/SideBySideLayout.swift
  - Sources/Features/Home/HomeRootView.swift
  - Sources/Core/Store/StoreManager.swift
  - Sources/Features/Home/HomeHostController.swift
  - Tests/FoodEntropyTests/SideBySideLayoutTests.swift
  - CLAUDE.md
  - project.yml
  - Sources/Core/Ad/BannerAdView.swift
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Settings/SettingsView.swift
  - Sources/Features/Settings/SettingsHostController.swift
  - Tests/FoodEntropyTests/StoreManagerTests.swift
  - Tests/FoodEntropyTests/BannerAdViewTests.swift
-->

---
### Requirement: A pushed settings screen yields to the settings column

When a settings screen that was pushed from the home screen's settings control is on the stack and the space becomes wide enough for two columns, the system SHALL return to the home screen through the router, after the size transition completes, so that settings appears only once — in the leading column.

#### Scenario: Unfolding while settings is open

- **WHEN** the user opens settings from the home screen on the iPhone Duo outer display and then unfolds the device
- **THEN** the pushed settings screen is removed and the two-column layout shows settings in the leading column and the home screen in the trailing column

#### Scenario: Rotating the inner display while settings is open

- **WHEN** the user opens settings on the inner display held in portrait and then rotates it to landscape
- **THEN** the pushed settings screen is removed and the two-column layout appears

<!-- @trace
source: adapt-iphone-duo
updated: 2026-10-07
code:
  - Sources/Features/Home/SideBySideLayout.swift
  - Sources/Features/Home/HomeRootView.swift
  - Sources/Core/Store/StoreManager.swift
  - Sources/Features/Home/HomeHostController.swift
  - Tests/FoodEntropyTests/SideBySideLayoutTests.swift
  - CLAUDE.md
  - project.yml
  - Sources/Core/Ad/BannerAdView.swift
  - Sources/Features/Home/HomeView.swift
  - Sources/Features/Settings/SettingsView.swift
  - Sources/Features/Settings/SettingsHostController.swift
  - Tests/FoodEntropyTests/StoreManagerTests.swift
  - Tests/FoodEntropyTests/BannerAdViewTests.swift
-->