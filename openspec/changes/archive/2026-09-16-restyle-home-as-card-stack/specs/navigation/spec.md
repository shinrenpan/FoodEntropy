## ADDED Requirements

### Requirement: Default navigation is a push onto the stack the caller belongs to

The system SHALL default to a push transition when navigating to another screen, so that returning from that screen pops back and triggers the previous screen's appearance callback. A pushed screen SHALL cover the full height its stack occupies.

The app's own screens SHALL live on one root navigation stack. A screen presented modally MAY carry a navigation stack of its own; when it does, a push started from within it SHALL land on that stack, so returning leads back to the presented screen rather than to the root. The router SHALL derive the stack from the screen that asked to navigate, never from a stored reference, so neither caller needs to know which stack it is on.

#### Scenario: Adding a food item and returning refreshes the home screen

- **WHEN** the user opens the add form from the home screen, saves, and the form closes
- **THEN** the home screen is revealed by a pop and reflects the newly added item

#### Scenario: A pushed screen owns the full screen

- **WHEN** any screen is pushed onto the root stack
- **THEN** no persistent bottom bar remains beneath it, because the root carries none

#### Scenario: Returning from settings refreshes the home screen

- **WHEN** the user opens settings from the home screen and then taps back
- **THEN** the home screen is revealed by a pop and reloads its data, the same way it does when returning from the form

#### Scenario: Editing from within a presented list returns to that list

- **WHEN** the user opens a food item for editing from a list that is itself presented modally, and then leaves the form
- **THEN** the form pops back to that list rather than dismissing to the home screen, because the push landed on the presented screen's own stack

##### Example: where a push lands

| Pushed from | Lands on | Leaving the pushed screen returns to |
| --- | --- | --- |
| the home screen | the root stack | the home screen |
| settings, itself pushed | the root stack | settings |
| a modally presented list | that list's own stack | that list |

## MODIFIED Requirements

### Requirement: Deeplink parsing is centralised in one enum

The system SHALL parse every incoming URL through a single `Deeplink` enum initialiser that accepts only this app's URL scheme and returns nothing for an unrecognised host, and SHALL route every entry point — cold-launch URL, foreground URL, and notification tap — through that same enum and a single handler.

#### Scenario: Tapping an expiry notification opens the home screen

- **WHEN** the user taps an expiry notification, whether the app was terminated, backgrounded, or in the foreground
- **THEN** the app opens and the stack comes to rest on the home screen

#### Scenario: A notification without a deeplink payload still lands on the home screen

- **WHEN** a notification is tapped whose payload carries no deeplink value
- **THEN** the app falls back to the home destination rather than ignoring the tap

#### Scenario: An unrecognised URL is ignored

- **WHEN** the app is opened with a URL whose scheme is not this app's, or whose host is not a known destination
- **THEN** no navigation occurs and the app stays where it was

#### Scenario: A cold-launch URL is handled after the window is ready

- **WHEN** the app is launched from a terminated state by a deeplink URL
- **THEN** the destination is applied after the window has been made key and visible, so the routing acts on an assembled interface

### Requirement: A single food item is a deeplink destination

The system SHALL accept a deeplink that names one food item, and SHALL open that item's detail for editing rather than stopping at the home screen. The destination SHALL be reachable by the same centralized parsing every other entry point uses, so that no entry point carries navigation logic of its own.

A deeplink naming an item that is no longer active SHALL land on the home screen without reporting an error, because an item can legitimately be consumed, discarded, or deleted between the moment a link is offered and the moment it is followed.

Arriving at the item SHALL NOT depend on what was on screen when the deeplink was followed. When any screen is already presented above the home screen, the system SHALL return to the home screen **and** present the item's detail — returning to the home screen alone is a failure, not a partial success, because the user asked for an item and silently receives nothing.

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

#### Scenario: A malformed item link is rejected

- **WHEN** a URL names the item destination but carries no identifier, or one that is not a valid identifier
- **THEN** the URL resolves to no destination and nothing is navigated

##### Example: where the stack ends up

| On screen when the link is followed | Resulting stack |
| --- | --- |
| home screen | home screen, then the item's detail |
| another item's detail | home screen, then the requested item's detail |
| settings | home screen, then the requested item's detail |
| a bucket's list | home screen, then the requested item's detail |
| any of the above, item no longer active | home screen only |

##### Example: item URL parsing

| URL | Resolves to |
| --- | --- |
| `foodentropy://home` | the home screen |
| `foodentropy://item/<a valid identifier>` | that item's detail |
| `foodentropy://item/not-a-uuid` | nothing |
| `foodentropy://item` | nothing |
| `https://item/<a valid identifier>` | nothing |

## REMOVED Requirements

### Requirement: Default navigation is a push onto the single navigation stack

**Reason**: "One navigation stack for the whole app" stopped being true once a bucket's list is presented modally with a stack of its own. The push default itself is unchanged; what changes is that a push now lands on whichever stack the calling screen belongs to, which is what lets editing from within a presented list return to that list instead of dismissing to the home screen.

**Migration**: Replaced by "Default navigation is a push onto the stack the caller belongs to", which keeps the push default, keeps the app's own screens on one root stack, and states that a modally presented screen may carry its own stack that pushes land on. The router already derives the stack from the calling screen, so no routing code changes.
