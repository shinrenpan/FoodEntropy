## ADDED Requirements

### Requirement: A wide container shows settings beside the home screen

When the space the home screen is given is wider than it is tall, the system SHALL show two columns: settings in the leading column and the home screen (card stack, ad slot, add button) in the trailing column. When the space is not wider than it is tall, the system SHALL show the home screen alone, exactly as on a regular iPhone. On the devices this app supports, only the inner display of an iPhone Duo held in landscape produces a wide space; regular iPhones and the Duo outer display stay portrait (see `app-shell`).

The home screen SHALL keep its identity when the second column appears or disappears, so its scroll position, its open sheets, and its loaded state survive folding, unfolding, and rotation rather than being rebuilt.

The boundary between the columns SHALL follow the device's fold as reported by the system's division region:

- while the device is partially folded (the division region is active), each column SHALL end at its side of the fold and the fold's width SHALL be left empty between them;
- while the device lies flat (the division region is inactive), the boundary SHALL sit at the centre of the fold rather than at half the container's width.

The empty space left for the fold SHALL match the columns' background rather than showing the window's background.

#### Scenario: Holding the inner display in landscape

- **WHEN** an iPhone Duo is fully unfolded and held in landscape with the app on the home screen
- **THEN** settings is shown in the leading column and the home screen in the trailing column

#### Scenario: Partially folding keeps both columns off the fold

- **WHEN** the unfolded iPhone Duo is partially folded while showing both columns
- **THEN** each column ends at its side of the fold and nothing is drawn across it, at every fold angle short of flat

##### Example: Measured column widths on iPhone Duo

| Pose | Leading | Gap | Trailing | Notes |
| ---- | ------- | --- | -------- | ----- |
| Flat, landscape | 475 | 0 | 391 | container 867×553 pt, division 455–495 inactive |
| Partially folded, landscape | 455 | 40 | 371 | division 455–495 active; same at every bend angle |

Values measured in the iPhone Duo simulator (Xcode 27.1 RC, iOS 27.1) on 2026-10-07. The trailing widths 391 and 371 are on-screen readings truncated to whole points; the arithmetic values are 392 (867 − 475) and 372 (867 − 495), and tests assert the arithmetic values.

#### Scenario: Unfolding and folding do not jump the boundary

- **WHEN** the device moves between partially folded and flat while showing both columns
- **THEN** the boundary stays at the fold and each column changes only by its half of the fold's width

#### Scenario: Narrow space shows the home screen alone

- **WHEN** the app runs on a regular iPhone, on the iPhone Duo outer display, or on the inner display held in portrait
- **THEN** only the home screen is shown and no settings column appears

#### Scenario: Changing between one and two columns keeps the home screen

- **WHEN** the device is rotated or unfolded so that the layout changes between one and two columns
- **THEN** the home screen keeps its position in the card stack and any sheet it presented remains open

### Requirement: A pushed settings screen yields to the settings column

When a settings screen that was pushed from the home screen's settings control is on the stack and the space becomes wide enough for two columns, the system SHALL return to the home screen through the router, after the size transition completes, so that settings appears only once — in the leading column.

#### Scenario: Unfolding while settings is open

- **WHEN** the user opens settings from the home screen on the iPhone Duo outer display and then unfolds the device
- **THEN** the pushed settings screen is removed and the two-column layout shows settings in the leading column and the home screen in the trailing column

#### Scenario: Rotating the inner display while settings is open

- **WHEN** the user opens settings on the inner display held in portrait and then rotates it to landscape
- **THEN** the pushed settings screen is removed and the two-column layout appears

## MODIFIED Requirements

### Requirement: Settings is reached from the home screen's navigation bar

The system SHALL offer a settings control in the trailing position of the home screen's navigation bar whenever settings is not already visible beside the home screen, and SHALL open settings as a pushed screen that returns by the standard back control and the interactive back gesture. The control SHALL carry a settings label drawn from the String Catalog so it is named rather than icon-only in every language. While the two-column layout shows settings in the leading column, the control SHALL NOT be shown.

The home screen SHALL emit this navigation as an intent for its host to execute, in the same way it emits opening the add and edit forms, rather than presenting settings itself.

#### Scenario: Opening settings from the home screen

- **WHEN** the user taps the settings control in the home screen's navigation bar
- **THEN** the settings screen is pushed onto the same stack, showing a back control that returns to the home screen

#### Scenario: Returning from settings

- **WHEN** the user leaves settings by the back control or the back gesture
- **THEN** the home screen is revealed and reloads, so a preference changed in settings is reflected without relaunching

#### Scenario: A deeplink arriving while settings is open

- **WHEN** a food item deeplink arrives while the user is on the settings screen
- **THEN** settings is removed from the stack and the item's form is shown, rather than the form appearing on top of settings or the stack coming to rest on the home screen

#### Scenario: No settings control while settings is beside the home screen

- **WHEN** the two-column layout is showing settings in the leading column
- **THEN** the home screen's navigation bar shows no settings control, and the control returns as soon as the layout goes back to one column
