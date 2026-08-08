## ADDED Requirements

### Requirement: A food item may carry an optional recorded cost

The system SHALL allow a food item to carry an optional cost representing the total amount spent on that record, not a unit price. An item without a recorded cost SHALL behave exactly as before in every other respect.

#### Scenario: Recording an item without a cost

- **WHEN** the user records a food item and leaves the cost unset
- **THEN** the item is stored and behaves identically to items recorded before costs existed, participating normally in bucketing, sorting, and reminders

#### Scenario: One record means one purchase

- **WHEN** the user buys three cartons of milk and records them as a single item
- **THEN** the cost they enter represents the whole purchase, since there is no quantity to multiply by
