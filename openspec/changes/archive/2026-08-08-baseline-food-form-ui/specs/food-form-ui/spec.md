## ADDED Requirements

### Requirement: One form serves both adding and editing

The system SHALL use a single form screen with an add mode and an edit mode, SHALL title each mode distinctly from the String Catalog, SHALL prefill the edit mode from the item being edited, and SHALL create on save in add mode and update in edit mode.

#### Scenario: Adding starts from sensible defaults

- **WHEN** the user opens the form to add an item
- **THEN** the title reads as adding, the name is empty, the purchase date is today, the expiry date is three days out, and no photo is set

#### Scenario: Editing starts from the item's current values

- **WHEN** the user opens an existing item for editing
- **THEN** the title reads as editing and every field shows that item's stored value

---
### Requirement: Saving requires a name that is not blank

The system SHALL enable the save control only when the name contains a non-whitespace character, SHALL store the name with leading and trailing whitespace removed, and SHALL take no action if a save is somehow requested while the name is blank.

#### Scenario: An empty name cannot be saved

- **WHEN** the name field is empty or contains only spaces
- **THEN** the save control is disabled, so the user sees that saving is unavailable before attempting it

#### Scenario: Surrounding whitespace is not stored

- **WHEN** the user types a name padded with spaces and saves
- **THEN** the stored name has no leading or trailing whitespace

---
### Requirement: The expiry date can never precede the purchase date

The system SHALL restrict the expiry date selection to dates no earlier than the current purchase date, and SHALL move the expiry date forward to match when the purchase date is changed to a later date.

#### Scenario: Selecting an earlier expiry date is not offered

- **WHEN** the user opens the expiry date selection
- **THEN** dates before the purchase date are not selectable

#### Scenario: Moving the purchase date past the expiry date carries it along

- **WHEN** the user changes the purchase date to a date after the current expiry date
- **THEN** the expiry date moves to that same date, leaving no invalid range

---
### Requirement: Leaving with unsaved changes asks first, and leaving unchanged does not

The system SHALL compare the current field values against a snapshot taken when the form opened to decide whether changes exist, SHALL exclude presentation-only flags from that snapshot, SHALL ask for confirmation before discarding when changes exist, and SHALL leave immediately when they do not.

#### Scenario: Backing out of an untouched form does not interrupt

- **WHEN** the user opens the form, changes nothing, and leaves
- **THEN** the form closes immediately with no prompt

#### Scenario: Backing out after editing asks

- **WHEN** the user changes a field and then leaves
- **THEN** a confirmation asks whether to discard the changes

#### Scenario: Choosing to keep editing preserves the work

- **WHEN** the user declines to discard
- **THEN** the form stays open with the changes intact, and the prompt itself does not count as a change

---
### Requirement: The form provides its own back control

The system SHALL hide the system back control and provide its own cancel control, so that leaving the screen passes through the view model's discard check.

#### Scenario: The back control routes through the discard check

- **WHEN** the user taps the control that leaves the form
- **THEN** the view model decides whether to prompt or close, rather than the screen being dismissed directly

---
### Requirement: Photos are chosen from a menu and removed only when one exists

The system SHALL offer taking a photo and choosing from the library when the photo area is tapped, SHALL additionally offer removing the photo only while one is set, and SHALL show a large preview of the chosen photo below the fields.

#### Scenario: Choosing a photo source

- **WHEN** the user taps the photo area with no photo set
- **THEN** the choices are taking a photo, choosing from the library, and cancelling — with no remove option

#### Scenario: Removing an existing photo

- **WHEN** the user taps the photo area while a photo is set
- **THEN** removing the photo is offered alongside the other choices

#### Scenario: Confirming what was captured

- **WHEN** a photo has been chosen
- **THEN** a large preview appears below the fields, big enough to judge the contents

---
### Requirement: Saving writes, then requests permission, then reconciles reminders, then closes

The system SHALL, on a successful save, write the record first, then request notification authorisation if it has not yet been decided, then reconcile notification scheduling from the current active items, and finally close the form.

#### Scenario: The permission prompt follows the first save

- **WHEN** the user saves their first item
- **THEN** the record is written and the permission prompt appears afterwards, when its purpose is evident

#### Scenario: The reminder reflects what was just saved

- **WHEN** the user saves a new item or changes an existing item's expiry date
- **THEN** reconciliation runs against the freshly written data, so the reminder matches what was saved

#### Scenario: The list is current when the form closes

- **WHEN** the form closes after saving
- **THEN** the home screen shows the saved change

---
### Requirement: The form edits fields only

The system SHALL NOT offer deleting, marking consumed, marking wasted, or extending the expiry date from the form; those actions belong to the list.

#### Scenario: No status actions on the form

- **WHEN** the user opens an item for editing
- **THEN** the screen offers only field editing, saving, and leaving — with no way to resolve or delete the item from there
