## MODIFIED Requirements

### Requirement: Source files follow the MVVMC folder convention

The system SHALL organise sources as `Sources/App` for the shell and router, `Sources/Core` for cross-screen concerns grouped by subject, and `Sources/Features/<Feature>/` for each screen. Each feature folder SHALL contain that screen's HostController, View, ViewModel, and the ViewModel's models extension. Code consumed by both the app and an extension SHALL live under `Sources/Core` and SHALL be included in every target that consumes it, rather than being duplicated per target.

#### Scenario: A new screen is added

- **WHEN** a new screen is introduced
- **THEN** its HostController, View, ViewModel, and ViewModel models extension are placed together under a single folder named for that feature

#### Scenario: Logic is shared by more than one screen

- **WHEN** a concern is consumed by more than one screen
- **THEN** it lives under `Sources/Core` in a subfolder named for the subject, not inside any one feature folder

#### Scenario: A presentation is consumed by both the app and an extension

- **WHEN** a view is rendered by both the app and an extension
- **THEN** it lives under `Sources/Core` and is a member of both targets, so that a change to it reaches both without a second copy existing

## ADDED Requirements

### Requirement: The widget extension is declared alongside the app in the generated project

The system SHALL declare the widget extension as a target in the project definition from which the Xcode project is generated, and SHALL declare the shared app group on both the app and the extension. Neither the target nor the entitlement SHALL be configured only inside the Xcode project file, because that file is generated and such edits are lost.

#### Scenario: The project is regenerated

- **WHEN** the Xcode project is regenerated from its definition
- **THEN** the widget extension target and the app group entitlement on both targets are present without manual repair

#### Scenario: The app group is declared on only one target

- **WHEN** the app group is present on the app but absent from the extension
- **THEN** the extension cannot reach the shared store, so both declarations are required for the widget to show any data
