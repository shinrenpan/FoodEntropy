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

## REMOVED Requirements

### Requirement: Default navigation is a push onto the single navigation stack

**Reason**: "One navigation stack for the whole app" stopped being true once a bucket's list is presented modally with a stack of its own. The push default itself is unchanged; what changes is that a push now lands on whichever stack the calling screen belongs to, which is what lets editing from within a presented list return to that list instead of dismissing to the home screen.

**Migration**: Replaced by "Default navigation is a push onto the stack the caller belongs to", which keeps the push default, keeps the app's own screens on one root stack, and states that a modally presented screen may carry its own stack that pushes land on. The router already derives the stack from the calling screen, so no routing code changes.
