## ADDED Requirements

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

## REMOVED Requirements

### Requirement: Default navigation is a push onto the current tab's stack

**Reason**: The root no longer holds tabs, so "the current tab's stack" names something that does not exist. The push default itself is unchanged; only the description of what it pushes onto changes.

**Migration**: Replaced by "Default navigation is a push onto the single navigation stack", which keeps the push default and the pop-reveals-and-reloads behavior, and drops the scenario about a pushed form hiding the tab bar — there is no tab bar to hide.

## MODIFIED Requirements

### Requirement: A single food item is a deeplink destination

The system SHALL accept a deeplink that names one food item, and SHALL open that item's detail for editing rather than stopping at the list. The destination SHALL be reachable by the same centralized parsing every other entry point uses, so that no entry point carries navigation logic of its own.

A deeplink naming an item that is no longer active SHALL land on the home list without reporting an error, because an item can legitimately be consumed, discarded, or deleted between the moment a link is offered and the moment it is followed.

#### Scenario: Following a link to an item

- **WHEN** an entry point supplies a deeplink naming an active food item
- **THEN** the stack returns to the home list and that item's detail is presented for editing

#### Scenario: Following a link to an item that is gone

- **WHEN** an entry point supplies a deeplink naming an item that has been consumed, discarded, or deleted
- **THEN** the stack returns to the home list, no detail is presented, and no error is surfaced

#### Scenario: Following two item links in succession

- **WHEN** a second item deeplink is followed while a detail is already presented
- **THEN** the second item's detail replaces the first rather than stacking on top of it

#### Scenario: A malformed item link is rejected

- **WHEN** a URL names the item destination but carries no identifier, or one that is not a valid identifier
- **THEN** the URL resolves to no destination and nothing is navigated

##### Example: item URL parsing

| URL | Resolves to |
| --- | --- |
| `foodentropy://home` | the home list |
| `foodentropy://item/<a valid identifier>` | that item's detail |
| `foodentropy://item/not-a-uuid` | nothing |
| `foodentropy://item` | nothing |
| `https://item/<a valid identifier>` | nothing |
