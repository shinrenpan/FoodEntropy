## ADDED Requirements

### Requirement: The persisted model stays CloudKit-safe whether or not sync is on

The system SHALL give every non-optional persisted attribute a default value, SHALL NOT declare any attribute unique, and SHALL make any future relationship optional — regardless of whether iCloud sync is currently enabled. Required-field validation SHALL be performed by the entry form rather than by database constraints.

#### Scenario: Enabling sync on an existing local database succeeds

- **WHEN** a user who has been using the app with sync off enables iCloud sync and relaunches
- **THEN** the store is created against the same schema without migration, and the app launches normally

#### Scenario: A missing required value is rejected before it reaches the store

- **WHEN** the user tries to save a food item without a name
- **THEN** the form rejects the save, since the store itself would have accepted an empty string

---
### Requirement: Record status is persisted as a raw string and unknown values fall back to active

The system SHALL persist the record status as its raw string value, and SHALL interpret an unrecognised stored value as `active` when converting to the domain model.

#### Scenario: A value written by a newer version is read by an older one

- **WHEN** a record synced from another device carries a status string this version does not recognise
- **THEN** the item is presented as an active item rather than being discarded or causing a failure

---
### Requirement: The persistence layer never exposes its model type

The system SHALL convert every persisted entity to a domain model at the manager boundary, SHALL define that conversion on the entity itself, and SHALL NOT return, accept, or otherwise expose the persisted model type through the manager's public interface.

#### Scenario: A view model requests the active list

- **WHEN** a view model asks the manager for the current food items
- **THEN** it receives domain values it can hold and compare freely, with no context-bound persistence objects among them

#### Scenario: A view model is tested without a database

- **WHEN** a unit test drives a view model with domain values injected directly
- **THEN** no store, container, or persisted entity is required for the test to run

---
### Requirement: Data is delivered by explicit re-fetch, not by automatic observation

The system SHALL provide data through a main-actor manager that callers query explicitly, and SHALL NOT bind views directly to the store through automatic query observation.

#### Scenario: The list reflects a change made on another screen

- **WHEN** the user returns to the list after adding or editing an item on another screen
- **THEN** the list shows the change because the screen re-fetched on appearing, not because the store pushed an update

---
### Requirement: Query ordering is part of the data contract

The system SHALL return active items sorted by expiry date ascending and then by creation date ascending, and SHALL return resolved items sorted by resolution time from newest to oldest.

#### Scenario: Items expiring on the same day keep a stable order

- **WHEN** several items share an expiry date and the list is fetched repeatedly
- **THEN** their relative order is the same every time, ordered by when they were created

#### Scenario: The soonest expiry appears first

- **WHEN** the active list is fetched
- **THEN** the item closest to expiry — including any already past it — appears before items expiring later

---
### Requirement: Resolving an item records the resolution time and strips its photo

The system SHALL, when marking an item consumed or wasted, set its record status, record the time of resolution, and clear its stored image data. Deleting an item SHALL remove the record entirely, and editing an item SHALL NOT alter its record status.

#### Scenario: A consumed item stops occupying image storage

- **WHEN** the user marks an item with a photo as consumed
- **THEN** the record is retained with its resolution time, and its image data is no longer stored

#### Scenario: Editing does not resolve an item

- **WHEN** the user edits an active item's name, dates, or photo
- **THEN** the item remains active with no resolution time recorded

---
### Requirement: Photos are downscaled and compressed before they are stored

The system SHALL resize a captured or selected photo so its longest side does not exceed the configured maximum, SHALL render that resize at a scale of one so the pixel limit is honoured on high-density displays, SHALL encode it as JPEG at the configured quality, and SHALL store the result as external-storage data that participates in sync.

#### Scenario: A high-resolution photo is reduced before storage

- **WHEN** the user picks a photo far larger than the configured maximum dimension
- **THEN** the stored data is a downscaled JPEG of a few hundred kilobytes rather than the original image

#### Scenario: A photo already within the limit is not enlarged

- **WHEN** the user picks a photo whose longest side is already within the maximum
- **THEN** it is encoded without being resized

---
### Requirement: Read failures yield empty results and write failures fail loudly only in debug

The system SHALL return an empty collection when a fetch fails, and SHALL raise a debug-build assertion when a save fails, in both cases without terminating the app.

#### Scenario: The store cannot be read

- **WHEN** a fetch fails at runtime
- **THEN** the caller receives an empty collection and the app continues running

#### Scenario: A save fails during development

- **WHEN** a save fails in a debug build
- **THEN** an assertion failure surfaces the problem immediately to the developer

---
### Requirement: Schema evolution is additive only

The system SHALL evolve its persisted schema by adding attributes only, and SHALL NOT change the type of, or remove, an existing attribute.

#### Scenario: A new field is needed

- **WHEN** a future feature requires a new piece of data on a food item
- **THEN** it is added as a new optional or defaulted attribute, leaving existing attributes untouched, because deployed CloudKit schemas cannot be altered or removed
