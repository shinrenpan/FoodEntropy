## ADDED Requirements

### Requirement: iCloud sync is opt-in and defaults to off

The system SHALL store the iCloud sync preference as a boolean that defaults to off for a fresh install, SHALL NOT upload any user data until the user turns it on, and SHALL NOT ask for a sync decision during first launch.

#### Scenario: A new user's data stays local

- **WHEN** a user installs the app and starts recording food items without visiting Settings
- **THEN** nothing is uploaded, and the app never interrupts them with a sync consent prompt

#### Scenario: Turning the switch on is itself the consent

- **WHEN** the user turns on iCloud sync in Settings
- **THEN** that action alone authorises syncing, with no separate consent dialog

---
### Requirement: A change to the sync setting applies at the next launch

The system SHALL decide whether to attach CloudKit when the store is created at launch, SHALL NOT swap the store while the app is running, and SHALL tell the user that a restart is required when the setting is changed.

#### Scenario: Toggling the switch shows a restart notice

- **WHEN** the user changes the iCloud sync setting
- **THEN** the preference is saved and the user is told the change takes effect after restarting the app

#### Scenario: The current session's behaviour is unchanged

- **WHEN** the user turns sync on and continues using the app without restarting
- **THEN** the session continues against the store it launched with, and no syncing begins

---
### Requirement: Both switch positions use the same local store

The system SHALL use the same on-device store regardless of whether CloudKit is attached, so that switching in either direction requires no data migration or file relocation.

#### Scenario: Turning sync on preserves existing local data

- **WHEN** a user who already has food items turns sync on and restarts
- **THEN** the existing items are still present locally, and no migration step runs

#### Scenario: Turning sync off preserves existing local data

- **WHEN** a user turns sync off and restarts
- **THEN** all items remain available on the device

---
### Requirement: Enabling sync uploads existing data without custom migration code

The system SHALL rely on the CloudKit-backed container to mirror already-stored local records to the user's private database, and SHALL NOT implement its own data-transfer step.

#### Scenario: Previously recorded items reach a second device

- **WHEN** a user with existing items enables sync, restarts, and later opens the app on another device signed in to the same Apple ID
- **THEN** the previously recorded items and their photos appear there, arriving progressively rather than instantly

---
### Requirement: Disabling sync stops syncing without deleting the cloud copy

The system SHALL leave previously synced records in the user's private database when sync is turned off, and SHALL merge them back when sync is later turned on again.

#### Scenario: Turning sync off leaves other devices intact

- **WHEN** the user turns sync off on one device and restarts
- **THEN** records already synced remain available on the user's other devices

#### Scenario: Re-enabling sync reunites the two sides

- **WHEN** the user turns sync back on and restarts
- **THEN** local records and previously synced cloud records are merged rather than one replacing the other

---
### Requirement: Photos are covered by sync

The system SHALL store photos such that they are carried by the same sync mechanism as the rest of the record, and SHALL NOT keep them in a location outside that mechanism.

#### Scenario: A synced item arrives with its photo

- **WHEN** an item with a photo syncs to another device
- **THEN** the photo arrives with it, rather than the item appearing without its image
