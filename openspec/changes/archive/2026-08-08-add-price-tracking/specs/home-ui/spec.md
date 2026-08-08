## ADDED Requirements

### Requirement: The amount about to expire is surfaced while the food can still be saved

The system SHALL display the total recorded cost of active items whose expiry status is near-expiry, SHALL phrase it as a lower bound rather than an exact figure, and SHALL format the currency according to the device's region. Items that are already expired or still fresh SHALL NOT contribute to this amount.

#### Scenario: Money is named while there is still time to act

- **WHEN** the user has near-expiry items with recorded costs
- **THEN** the home screen shows the summed amount phrased as a lower bound, so the user learns what is at stake while the food can still be eaten

#### Scenario: The figure never claims to be complete

- **WHEN** only some near-expiry items have recorded costs
- **THEN** the amount is still phrased as a lower bound, and the wording does not change based on how many items have costs

#### Scenario: Fresh stock is not counted

- **WHEN** the user has expensive items that are still well within their expiry dates
- **THEN** they do not contribute to the amount, which reports only what is at risk rather than the value of everything stored

#### Scenario: Already-expired items are excluded

- **WHEN** the user has expired items carrying recorded costs
- **THEN** they do not contribute to this amount, which speaks only to what can still be saved

---
### Requirement: The upcoming amount disappears rather than reporting zero

The system SHALL omit the upcoming-expiry amount entirely when no near-expiry item carries a recorded cost, and SHALL NOT display a zero amount or a prompt encouraging the user to record costs.

#### Scenario: A user who records no costs sees no amount

- **WHEN** the user has never entered a cost
- **THEN** the home screen looks as it did before this feature existed, with no zero figure and no prompt occupying space

#### Scenario: No near-expiry items at all

- **WHEN** nothing is currently near expiry
- **THEN** no amount is shown

---
### Requirement: Discarded cost appears as secondary information in waste statistics

The system SHALL show the total recorded cost of items wasted within the statistics window as secondary information within the waste statistics section, SHALL keep the waste percentage as that section's primary figure, and SHALL use the same rolling window as the existing statistics.

#### Scenario: The discarded amount does not become the headline

- **WHEN** the user views waste statistics with some wasted items carrying costs
- **THEN** the waste percentage remains the section's main figure and the amount appears alongside it as supporting detail, so a small amount cannot read as reassurance

#### Scenario: The discarded amount follows the same window as the percentage

- **WHEN** an item was wasted before the start of the statistics window
- **THEN** its cost is excluded from the amount, consistently with how it is already excluded from the percentage
