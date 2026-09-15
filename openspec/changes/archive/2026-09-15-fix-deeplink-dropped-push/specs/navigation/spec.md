## MODIFIED Requirements

### Requirement: A single food item is a deeplink destination

The system SHALL accept a deeplink that names one food item, and SHALL open that item's detail for editing rather than stopping at the list. The destination SHALL be reachable by the same centralized parsing every other entry point uses, so that no entry point carries navigation logic of its own.

A deeplink naming an item that is no longer active SHALL land on the home list without reporting an error, because an item can legitimately be consumed, discarded, or deleted between the moment a link is offered and the moment it is followed.

Arriving at the item SHALL NOT depend on what was on screen when the deeplink was followed. When any screen is already presented above the home list, the system SHALL return to the home list **and** present the item's detail — returning to the list alone is a failure, not a partial success, because the user asked for an item and silently receives nothing.

#### Scenario: Following a link to an item

- **WHEN** an entry point supplies a deeplink naming an active food item
- **THEN** the stack returns to the home list and that item's detail is presented for editing

#### Scenario: Following a link to an item that is gone

- **WHEN** an entry point supplies a deeplink naming an item that has been consumed, discarded, or deleted
- **THEN** the stack returns to the home list, no detail is presented, and no error is surfaced

#### Scenario: Following two item links in succession

- **WHEN** a second item deeplink is followed while a detail is already presented
- **THEN** the second item's detail replaces the first rather than stacking on top of it

#### Scenario: Following an item link from any other screen

- **WHEN** an item deeplink is followed while a screen other than a food item detail is presented above the home list
- **THEN** that screen is removed and the item's detail is presented, rather than the stack coming to rest on the home list with nothing presented

#### Scenario: A malformed item link is rejected

- **WHEN** a URL names the item destination but carries no identifier, or one that is not a valid identifier
- **THEN** the URL resolves to no destination and nothing is navigated

##### Example: where the stack ends up

| On screen when the link is followed | Resulting stack |
| --- | --- |
| home list | home list, then the item's detail |
| another item's detail | home list, then the requested item's detail |
| settings | home list, then the requested item's detail |
| any of the above, item no longer active | home list only |

##### Example: item URL parsing

| URL | Resolves to |
| --- | --- |
| `foodentropy://home` | the home list |
| `foodentropy://item/<a valid identifier>` | that item's detail |
| `foodentropy://item/not-a-uuid` | nothing |
| `foodentropy://item` | nothing |
| `https://item/<a valid identifier>` | nothing |
