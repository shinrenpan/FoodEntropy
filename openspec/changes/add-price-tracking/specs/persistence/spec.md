## ADDED Requirements

### Requirement: The recorded cost is persisted as an optional attribute and survives resolution

The system SHALL persist the recorded cost as an optional attribute, added without altering any existing attribute, and SHALL retain it when an item is marked consumed or wasted. Unlike the item's photo, the cost SHALL NOT be cleared on resolution.

#### Scenario: A resolved item keeps its cost

- **WHEN** the user marks an item that has a recorded cost as consumed or wasted
- **THEN** the stored record retains that cost, so it remains available to waste statistics — while its photo is still cleared as before

#### Scenario: Adding the attribute does not disturb existing records

- **WHEN** a user with existing food items updates to a version that introduces the cost attribute
- **THEN** their items load normally with no recorded cost, and no migration prompt or data loss occurs
