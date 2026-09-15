## ADDED Requirements

### Requirement: The home screen is a stack of cards and the working list sits behind one of them

The system SHALL present the home screen as a single stack of five cards — current status, waste statistics, and one card per expiry bucket — with the ad slot pinned above the stack and an add button pinned across the bottom. Exactly one card SHALL be fully shown at a time; the others SHALL show only their leading edge, carrying enough for the user to choose between them. There SHALL NOT be a separate analytics screen.

The home screen SHALL NOT display individual food rows. The working list of a bucket SHALL be reached from that bucket's card.

#### Scenario: Choosing what to look at

- **WHEN** the user opens the app
- **THEN** all five cards are visible at once, each showing at least its name and its headline figure, so the user can pick one without scrolling

#### Scenario: Adding an item is always reachable

- **WHEN** the user has scrolled anywhere on the home screen
- **THEN** the add button remains visible at the bottom of the screen

### Requirement: Tapping a card brings it forward, and a second tap opens that bucket's list

The system SHALL bring a card fully into view when it is tapped, without presenting anything over the home screen. When a card that is already fully in view represents a bucket that holds items, a further tap SHALL open that bucket's list. A card representing a summary, or a bucket holding no items, SHALL NOT open anything however many times it is tapped.

A bucket card that a further tap would open SHALL carry a visible indicator of that, so the second tap is not a hidden interaction. No other card SHALL carry that indicator.

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

## MODIFIED Requirements

### Requirement: Items are grouped into three expiry buckets, most urgent first, and empty buckets still appear

The system SHALL group active items into expired, near-expiry, and fresh buckets, SHALL give each bucket a card labelled with its name and count, SHALL present a bucket's card even when it holds no items, and SHALL keep each bucket in the order the data layer supplied.

The cards SHALL be ordered by urgency — expired, then near-expiry, then fresh — except that whichever card is fully in view is placed last in the stack so nothing overlaps it.

#### Scenario: Nothing has expired

- **WHEN** the user has no expired items
- **THEN** the expired bucket's card is still shown, with a count of zero, so the user can confirm at a glance that nothing is overdue

#### Scenario: Items within a bucket are ordered by urgency

- **WHEN** a bucket's list is opened and it holds several items
- **THEN** they appear in the order the data layer returned, soonest expiry first, without the screen re-sorting them

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

### Requirement: A hint describes the gestures that are not otherwise discoverable

The system SHALL display a hint describing the tap, swipe, and long-press actions available on a row, positioned where those rows are shown.

#### Scenario: Discovering the long-press menu

- **WHEN** the user opens a bucket's list and reaches the end of it
- **THEN** a hint explains that tapping edits, swiping marks consumed or deletes, and long-pressing offers extending or marking wasted

## REMOVED Requirements

### Requirement: The home screen carries both the current overview and the working list

**Reason**: The home screen stopped carrying the working list. Holding both roles was what crowded it: two summary panels filled the first screen and the first food row appeared about three-quarters of the way down, clipped by the pinned add button, while the status chart repeated what the bucket headers below it already said. The home screen is now the overview alone.

**Migration**: Replaced by "The home screen is a stack of cards and the working list sits behind one of them", which keeps the ad slot above and the add button below, keeps there being no separate analytics screen, and moves the rows into a bucket's list reached from that bucket's card.
