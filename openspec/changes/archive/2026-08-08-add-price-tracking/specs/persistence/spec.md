## ADDED Requirements

### Requirement: The recorded cost is persisted as an optional attribute and survives resolution

The system SHALL persist the recorded cost as an optional attribute, added without altering any existing attribute, and SHALL retain it when an item is marked consumed or wasted. Unlike the item's photo, the cost SHALL NOT be cleared on resolution.

#### Scenario: A resolved item keeps its cost

- **WHEN** the user marks an item that has a recorded cost as consumed or wasted
- **THEN** the stored record retains that cost, so it remains available to waste statistics — while its photo is still cleared as before

#### Scenario: Adding the attribute does not disturb existing records

- **WHEN** a user with existing food items updates to a version that introduces the cost attribute
- **THEN** their items load normally with no recorded cost, and no migration prompt or data loss occurs

---
### Requirement: Every attribute must be written at least once before deploying the schema

The system SHALL, before deploying a schema to the production environment, ensure each attribute — including optional ones — has actually been written with a value in the development environment, and SHALL verify the resulting field list rather than assuming the model definition was mirrored.

#### Scenario: An optional attribute that no record has ever set

- **WHEN** a new optional attribute exists in the model but no record has yet been saved with a value for it
- **THEN** no corresponding field exists in the development schema, and deploying at that point ships a production schema missing that field

#### Scenario: The missing field surfaces only later, in production

- **WHEN** a production schema lacks a field and a user's record sets that attribute
- **THEN** the value cannot sync, because production does not create fields on demand — and nothing in the app reports the failure

#### Scenario: Verifying before deployment

- **WHEN** preparing to deploy after adding attributes
- **THEN** each attribute is exercised with a real value first, and the development field list is checked against the model before the deployment is confirmed
