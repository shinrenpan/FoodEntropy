## ADDED Requirements

### Requirement: A single food item is a deeplink destination

The system SHALL accept a deeplink that names one food item, and SHALL open that item's detail for editing rather than stopping at the list. The destination SHALL be reachable by the same centralized parsing every other entry point uses, so that no entry point carries navigation logic of its own.

A deeplink naming an item that is no longer active SHALL land on the home list without reporting an error, because an item can legitimately be consumed, discarded, or deleted between the moment a link is offered and the moment it is followed.

#### Scenario: Following a link to an item

- **WHEN** an entry point supplies a deeplink naming an active food item
- **THEN** the home tab is selected and that item's detail is presented for editing

#### Scenario: Following a link to an item that is gone

- **WHEN** an entry point supplies a deeplink naming an item that has been consumed, discarded, or deleted
- **THEN** the home tab is selected, no detail is presented, and no error is surfaced

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
