## MODIFIED Requirements

### Requirement: A single food item is a deeplink destination

The system SHALL accept a deeplink that names one food item, and SHALL open that item's detail for editing rather than stopping at the home screen. The destination SHALL be reachable by the same centralized parsing every other entry point uses, so that no entry point carries navigation logic of its own.

A deeplink naming an item that is no longer active SHALL land on the home screen without reporting an error, because an item can legitimately be consumed, discarded, or deleted between the moment a link is offered and the moment it is followed.

Arriving at the item SHALL NOT depend on what was on screen when the deeplink was followed. When any screen is already presented above the home screen — pushed onto the stack, or presented modally above it such as a bucket's list sheet or the privacy policy sheet — the system SHALL remove it, return to the home screen **and** present the item's detail; returning to the home screen alone is a failure, not a partial success, because the user asked for an item and silently receives nothing. Leaving a modal sheet in place with the detail hidden beneath it is the same failure.

#### Scenario: Following a link to an item

- **WHEN** an entry point supplies a deeplink naming an active food item
- **THEN** the stack returns to the home screen and that item's detail is presented for editing

#### Scenario: Following a link to an item that is gone

- **WHEN** an entry point supplies a deeplink naming an item that has been consumed, discarded, or deleted
- **THEN** the stack returns to the home screen, no detail is presented, and no error is surfaced

#### Scenario: Following two item links in succession

- **WHEN** a second item deeplink is followed while a detail is already presented
- **THEN** the second item's detail replaces the first rather than stacking on top of it

#### Scenario: Following an item link from any other screen

- **WHEN** an item deeplink is followed while a screen other than a food item detail is presented above the home screen
- **THEN** that screen is removed and the item's detail is presented, rather than the stack coming to rest on the home screen with nothing presented

#### Scenario: Following an item link while a sheet is open

- **WHEN** an item deeplink is followed while a bucket's list, or any other screen, is presented modally above the home screen
- **THEN** the modal screen is dismissed and the item's detail is visible on top of the home screen, rather than being pushed beneath the sheet where the user cannot see it

#### Scenario: A malformed item link is rejected

- **WHEN** a URL names the item destination but carries no identifier, or one that is not a valid identifier
- **THEN** the URL resolves to no destination and nothing is navigated

##### Example: where the stack ends up

| On screen when the link is followed | Resulting stack | Modal screens afterwards |
| --- | --- | --- |
| home screen | home screen, then the item's detail | none |
| another item's detail | home screen, then the requested item's detail | none |
| settings | home screen, then the requested item's detail | none |
| a bucket's list sheet | home screen, then the requested item's detail | none |
| a bucket's list sheet with an item's edit form pushed inside it | home screen, then the requested item's detail | none |
| the privacy policy sheet | home screen, then the requested item's detail | none |
| any of the above, item no longer active | home screen only | none |

##### Example: item URL parsing

| URL | Resolves to |
| --- | --- |
| `foodentropy://home` | the home screen |
| `foodentropy://item/<a valid identifier>` | that item's detail |
| `foodentropy://item/not-a-uuid` | nothing |
| `foodentropy://item` | nothing |
| `https://item/<a valid identifier>` | nothing |

### Requirement: Deeplink parsing is centralised in one enum

The system SHALL parse every incoming URL through a single `Deeplink` enum initialiser that accepts only this app's URL scheme and returns nothing for an unrecognised host, and SHALL route every entry point — cold-launch URL, foreground URL, and notification tap — through that same enum and a single handler. Arriving at the home destination SHALL dismiss any screen presented modally above the home screen, so that "coming to rest on the home screen" means the home screen is what the user sees.

#### Scenario: Tapping an expiry notification opens the home screen

- **WHEN** the user taps an expiry notification, whether the app was terminated, backgrounded, or in the foreground
- **THEN** the app opens and the stack comes to rest on the home screen

#### Scenario: Tapping a notification while a sheet is open

- **WHEN** the user taps an expiry notification while a bucket's list sheet is open in the foreground app
- **THEN** the sheet is dismissed and the home screen is shown

#### Scenario: A notification without a deeplink payload still lands on the home screen

- **WHEN** a notification is tapped whose payload carries no deeplink value
- **THEN** the app falls back to the home destination rather than ignoring the tap

#### Scenario: An unrecognised URL is ignored

- **WHEN** the app is opened with a URL whose scheme is not this app's, or whose host is not a known destination
- **THEN** no navigation occurs and the app stays where it was

#### Scenario: A cold-launch URL is handled after the window is ready

- **WHEN** the app is launched from a terminated state by a deeplink URL
- **THEN** the destination is applied after the window has been made key and visible, so the routing acts on an assembled interface
