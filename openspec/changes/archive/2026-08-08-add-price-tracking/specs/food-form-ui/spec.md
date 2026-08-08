## ADDED Requirements

### Requirement: The form accepts an optional cost alongside the purchase date

The system SHALL offer a cost field in the same section as the purchase date, SHALL accept numeric input including decimals through a numeric keypad, SHALL NOT require it in order to save, and SHALL count a change to it as an unsaved change. The user SHALL NOT enter or choose a currency symbol.

#### Scenario: Saving without a cost

- **WHEN** the user fills in a valid name and leaves the cost empty
- **THEN** the save control is enabled and the item is stored without a cost

#### Scenario: Entering a cost

- **WHEN** the user taps the cost field
- **THEN** a numeric keypad appears and decimal values can be entered, with the currency presentation handled by the system rather than typed

#### Scenario: Changing only the cost still counts as an edit

- **WHEN** the user opens an existing item, changes only its cost, and leaves the form
- **THEN** the discard confirmation appears, because the cost is part of the comparison against the opening snapshot

#### Scenario: Adding a cost to an item recorded earlier

- **WHEN** the user opens an active item that has no cost and enters one
- **THEN** the cost is saved with that item and immediately counts toward the upcoming-expiry amount on the home screen
