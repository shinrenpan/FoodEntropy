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

### Requirement: AppRouter is a stateless main-actor singleton that derives context from the source

The system SHALL implement `AppRouter` as a `@MainActor` singleton that holds no navigation controller, window, or view controller, and SHALL derive the navigation stack from the `source` view controller passed to each call. All navigation between the app's own screens SHALL be confined to `AppRouter`; feature code SHALL NOT call `pushViewController`, `present`, or `dismiss` on its own screens. Dismissing a system-owned picker from its own delegate callback — where the system controller manages its own lifecycle — is not app navigation and is exempt.

#### Scenario: Navigating derives the stack from the caller

- **WHEN** a HostController asks `AppRouter` to navigate to a destination
- **THEN** the router uses that source's own navigation controller, so the destination lands on the app's one stack without the caller naming it

#### Scenario: Navigating from a controller outside any stack fails loudly in debug

- **WHEN** a navigation call is made from a source that has no navigation controller
- **THEN** no navigation occurs and a debug-build assertion failure signals the misuse

### Requirement: The interactive back gesture is enabled only for the default push transition

The system SHALL allow the interactive pop gesture only when the navigation stack holds more than one view controller and the top view controller arrived by the default push transition, and SHALL apply the same condition to the content-based pop gesture available from iOS 26.

#### Scenario: Swiping back from a pushed screen works

- **WHEN** the user swipes from the screen edge on a screen that arrived by push, with a previous screen in the stack
- **THEN** the gesture begins and pops the screen

#### Scenario: Swiping back from a custom-transition screen is refused

- **WHEN** the user swipes from the screen edge on a screen that arrived by a custom transition
- **THEN** the gesture does not begin, so a cancelled swipe cannot leave the screen mid-transition

#### Scenario: Swiping back at the root of the stack is refused

- **WHEN** the user swipes from the screen edge on the home screen, which is the root of the stack
- **THEN** the gesture does not begin

### Requirement: Deeplink parsing is centralised in one enum

The system SHALL parse every incoming URL through a single `Deeplink` enum initialiser that accepts only this app's URL scheme and returns nothing for an unrecognised host, and SHALL route every entry point — cold-launch URL, foreground URL, and notification tap — through that same enum and a single handler.

#### Scenario: Tapping an expiry notification opens the home list

- **WHEN** the user taps an expiry notification, whether the app was terminated, backgrounded, or in the foreground
- **THEN** the app opens and the stack comes to rest on the home list

#### Scenario: A notification without a deeplink payload still lands on the home list

- **WHEN** a notification is tapped whose payload carries no deeplink value
- **THEN** the app falls back to the home destination rather than ignoring the tap

#### Scenario: An unrecognised URL is ignored

- **WHEN** the app is opened with a URL whose scheme is not this app's, or whose host is not a known destination
- **THEN** no navigation occurs and the app stays where it was

#### Scenario: A cold-launch URL is handled after the window is ready

- **WHEN** the app is launched from a terminated state by a deeplink URL
- **THEN** the destination is applied after the window has been made key and visible, so the routing acts on an assembled interface

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
