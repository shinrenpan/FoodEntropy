## MODIFIED Requirements

### Requirement: All displayed state is reloaded each time the screen appears

The system SHALL load the sync preference, notification permission state, entitlement, product price, and version each time the settings screen appears, each time the app returns to the foreground while settings is visible, and each time the ad-removal entitlement changes. Settings can stay on screen indefinitely as the leading column beside the home screen (see `home-ui`), where it never re-appears, so reloading only on appearance would leave it stale.

#### Scenario: Returning after changing permission in system settings

- **WHEN** the user grants notification permission in the system Settings app and returns to this screen
- **THEN** the notification row reflects the new state

#### Scenario: Returning to the foreground while settings is beside the home screen

- **WHEN** settings is shown in the leading column, the user changes notification permission in the system Settings app, and returns to the app
- **THEN** the notification row reflects the new state without the user leaving or reopening settings

#### Scenario: Returning after purchasing on another device

- **WHEN** the user purchased on another device and later opens this screen
- **THEN** the purchase row shows the entitlement as held

#### Scenario: The entitlement changes while settings is visible

- **WHEN** the ad-removal entitlement is granted or revoked while settings is on screen
- **THEN** the purchase row and its explanatory text update immediately
