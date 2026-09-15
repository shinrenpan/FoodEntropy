## MODIFIED Requirements

### Requirement: Saving writes, then requests permission, then reconciles reminders, then closes

The system SHALL, on a successful save, write the record first, then request notification authorisation if it has not yet been decided, then reconcile notification scheduling from the current active items, and finally close the form.

While a save is in progress the system SHALL ignore any further save request and SHALL present its save control as unavailable, so that one save cannot produce a second record.

When the write fails, the system SHALL keep the form open with the user's entries intact, SHALL inform the user that the save did not happen, and SHALL NOT request notification authorisation, reconcile reminders, or close the form. The form SHALL become saveable again once the user dismisses that message.

#### Scenario: The permission prompt follows the first save

- **WHEN** the user saves their first item
- **THEN** the record is written and the permission prompt appears afterwards, when its purpose is evident

#### Scenario: The reminder reflects what was just saved

- **WHEN** the user saves a new item or changes an existing item's expiry date
- **THEN** reconciliation runs against the freshly written data, so the reminder matches what was saved

#### Scenario: The list is current when the form closes

- **WHEN** the form closes after saving
- **THEN** the home screen shows the saved change

#### Scenario: A second save request arrives while the first is still running

- **WHEN** the user triggers saving again before the first save has finished its permission request and reminder reconciliation
- **THEN** the second request is ignored, leaving exactly one record written and one reconciliation performed

#### Scenario: The write fails

- **WHEN** the record cannot be written
- **THEN** the form stays on screen with every entered value unchanged, the user is told the save did not happen, no permission prompt appears, and no reminder is rescheduled

#### Scenario: The user retries after a failure

- **WHEN** the user dismisses the failure message and saves again
- **THEN** the save runs as it would have the first time, and succeeds if the underlying problem is gone

##### Example: what the user sees per outcome

| Outcome           | Form after the attempt | Permission prompt | Reminders reconciled | Message shown |
| ----------------- | ---------------------- | ----------------- | -------------------- | ------------- |
| Write succeeds    | closed                 | yes, if undecided | yes                  | none          |
| Write fails       | open, entries intact   | no                | no                   | save failed   |
| Save already running | open, unchanged     | no                | no                   | none          |
