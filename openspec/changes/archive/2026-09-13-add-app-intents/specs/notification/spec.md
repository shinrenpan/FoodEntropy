## MODIFIED Requirements

### Requirement: Notifications carry a deeplink payload and are shown even in the foreground

The system SHALL attach a deeplink value to each notification's payload identifying the destination to open, and SHALL present expiry notifications as a banner with sound even while the app is in the foreground.

On iOS 27 and later the system SHALL additionally attach the entity identifier of the food item the notification is about, so the assistant can resolve a reference made while that notification is on screen. On earlier versions the notification SHALL carry the deeplink payload alone, with no error and no change to how it is presented.

#### Scenario: Tapping a notification opens the intended destination

- **WHEN** the user taps an expiry notification
- **THEN** the app opens at the destination named in the payload

#### Scenario: A reminder arrives while the app is open

- **WHEN** an expiry notification fires while the user is using the app
- **THEN** it is still presented as a banner with sound rather than being suppressed

#### Scenario: Referring to the item a notification is about

- **WHEN** an expiry notification is on screen on iOS 27 and the user refers to "this" in a request to the assistant
- **THEN** the assistant resolves the reference to the food item that notification was scheduled for

#### Scenario: The same notification on iOS 26

- **WHEN** an expiry notification is scheduled on iOS 26
- **THEN** it carries its deeplink payload, omits the entity identifier, and is scheduled and presented exactly as before
