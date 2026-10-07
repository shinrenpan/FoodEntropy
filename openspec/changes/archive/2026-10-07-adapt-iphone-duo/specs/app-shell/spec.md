## MODIFIED Requirements

### Requirement: The platform envelope is iPhone-only, portrait, iOS 26 or later

The system SHALL target iPhone only, SHALL declare portrait as its only supported interface orientation, SHALL require iOS 26 or later, SHALL build in Swift 6 language mode with complete strict-concurrency checking, and SHALL render correctly in both light and dark appearance.

The portrait declaration is honoured on regular iPhones and on the outer display of a foldable iPhone, so the interface never rotates there. The inner display of a foldable iPhone (iPhone Duo) ignores an app's declared orientations; there the system SHALL lay out from the space it is given rather than from the device orientation, as `home-ui` specifies for the home screen.

#### Scenario: Rotating a regular iPhone does not rotate the UI

- **WHEN** the user rotates a regular iPhone to landscape
- **THEN** the interface stays in portrait

#### Scenario: Rotating a foldable iPhone while closed does not rotate the UI

- **WHEN** the user rotates an iPhone Duo to landscape while it is closed and the outer display is in use
- **THEN** the interface stays in portrait, exactly as on a regular iPhone

#### Scenario: The inner display in landscape lays out for the space given

- **WHEN** the user opens an iPhone Duo and holds the inner display in landscape, fully or partially unfolded
- **THEN** the app runs full-screen in a landscape-shaped space and the home screen uses the wide layout defined in `home-ui`, rather than a portrait layout stretched to the width

#### Scenario: Switching to dark appearance keeps the UI legible

- **WHEN** the system appearance changes between light and dark
- **THEN** every screen remains legible, with status colours distinguishable in both appearances
