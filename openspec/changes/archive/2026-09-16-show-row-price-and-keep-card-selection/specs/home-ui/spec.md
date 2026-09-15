## ADDED Requirements

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

## MODIFIED Requirements

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
