## ADDED Requirements

### Requirement: Settings is reached from the home screen's navigation bar

The system SHALL offer a settings control in the trailing position of the home screen's navigation bar, and SHALL open settings as a pushed screen that returns by the standard back control and the interactive back gesture. The control SHALL carry a settings label drawn from the String Catalog so it is named rather than icon-only in every language.

The home screen SHALL emit this navigation as an intent for its host to execute, in the same way it emits opening the add and edit forms, rather than presenting settings itself.

#### Scenario: Opening settings from the home screen

- **WHEN** the user taps the settings control in the home screen's navigation bar
- **THEN** the settings screen is pushed onto the same stack, showing a back control that returns to the home screen

#### Scenario: Returning from settings

- **WHEN** the user leaves settings by the back control or the back gesture
- **THEN** the home screen is revealed and reloads, so a preference changed in settings is reflected without relaunching

#### Scenario: A deeplink arriving while settings is open

- **WHEN** a food item deeplink arrives while the user is on the settings screen
- **THEN** settings is removed from the stack, rather than the item's form appearing on top of settings
