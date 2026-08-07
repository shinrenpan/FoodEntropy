## ADDED Requirements

### Requirement: Settings is organised into purchase, sync and notifications, and about

The system SHALL group the settings screen into a purchase section, a sync and notifications section, and an about section, and SHALL take all user-facing text from the String Catalog.

#### Scenario: Finding where to turn on syncing

- **WHEN** the user opens Settings looking for iCloud sync
- **THEN** it appears in the sync and notifications section, alongside the notification row

---
### Requirement: The purchase row reflects owned, available, and in-progress states

The system SHALL show an owned indicator that cannot be tapped once the ad-removal entitlement is held, SHALL otherwise show the product's display price on a tappable row, SHALL show a progress indicator in place of the price while a purchase or restore is running, and SHALL disable both the purchase and restore controls while either is running.

#### Scenario: A paying user sees confirmation rather than an offer

- **WHEN** a user who already holds the entitlement opens Settings
- **THEN** the row shows that it is purchased and cannot be tapped again

#### Scenario: A purchase in progress blocks both controls

- **WHEN** a purchase is under way
- **THEN** a progress indicator replaces the price, and neither purchase nor restore can be triggered

#### Scenario: A failed purchase is reported

- **WHEN** a purchase fails
- **THEN** the user is told the purchase did not complete

---
### Requirement: The price comes from the store and is not formatted by the app

The system SHALL display the product's own localised display price, and SHALL show nothing where the price would be when the product has not loaded.

#### Scenario: Price shown in the user's currency

- **WHEN** the product has loaded
- **THEN** the row shows the store's display price, already formatted for the user's region and currency

#### Scenario: The product failed to load

- **WHEN** the product could not be fetched
- **THEN** no price is shown in its place

---
### Requirement: The section's explanatory text changes with ownership

The system SHALL explain, before purchase, that this is a one-time purchase that permanently removes the home banner, and SHALL replace that text with an acknowledgement once the entitlement is held.

#### Scenario: Knowing what is on offer

- **WHEN** the user has not purchased
- **THEN** the section explains that a one-time purchase permanently removes the home banner ad

#### Scenario: Confirming the purchase took effect

- **WHEN** the user has purchased
- **THEN** the section text acknowledges the purchase and states that the home ad is removed

---
### Requirement: Toggling iCloud sync immediately explains that a restart is needed

The system SHALL present a notice, as soon as the sync toggle is changed, stating that the change applies the next time the app is opened.

#### Scenario: Turning on sync

- **WHEN** the user turns the iCloud sync toggle on
- **THEN** a notice appears explaining that syncing will take effect after the app is next opened

---
### Requirement: The notification row shows the current permission state and routes accordingly

The system SHALL display the current notification permission as enabled, disabled, or not yet set; SHALL request permission directly when it has not yet been set; and SHALL open this app's page in the system Settings app once permission has been decided either way.

#### Scenario: A user who has never been asked

- **WHEN** the row shows that notifications are not yet set and the user taps it
- **THEN** the system permission prompt appears

#### Scenario: A user who previously denied

- **WHEN** the row shows that notifications are disabled and the user taps it
- **THEN** the system Settings app opens at this app's page, since the in-app prompt can no longer be shown

#### Scenario: A user who wants to turn notifications off

- **WHEN** the row shows that notifications are enabled and the user taps it
- **THEN** the system Settings app opens, where the permission can be changed

---
### Requirement: The privacy policy opens inside the app and the version is shown

The system SHALL open the hosted privacy policy within the app as a dismissable sheet using the same URL declared in the App Store listing, and SHALL display the app's version together with its build number as read-only text.

#### Scenario: Reading the policy without leaving

- **WHEN** the user taps the privacy policy row
- **THEN** the policy page opens in a sheet over Settings and can be dismissed back to it

#### Scenario: Reporting which build is installed

- **WHEN** the user looks at the about section
- **THEN** both the version and the build number are shown

---
### Requirement: All displayed state is reloaded each time the screen appears

The system SHALL load the sync preference, notification permission state, entitlement, product price, and version each time the settings screen appears.

#### Scenario: Returning after changing permission in system settings

- **WHEN** the user grants notification permission in the system Settings app and returns to this screen
- **THEN** the notification row reflects the new state

#### Scenario: Returning after purchasing on another device

- **WHEN** the user purchased on another device and later opens this screen
- **THEN** the purchase row shows the entitlement as held
