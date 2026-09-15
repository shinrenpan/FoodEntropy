## ADDED Requirements

### Requirement: Colour on the card stack carries urgency and nothing else

The system SHALL colour a bucket card by the expiry status it represents, and SHALL give every card that represents a summary rather than a bucket a surface carrying no hue at all. A summary card's surface SHALL be the same in every colour scheme, so that it never approaches the colour of the screen behind it.

Every card SHALL be legible on its own surface: the system SHALL NOT place a separate background behind a card's contents in order to make them readable.

Adjacent cards in the stack SHALL be distinguishable from each other in every colour scheme, including where one card overlaps the one behind it.

#### Scenario: A summary card is not mistaken for a bucket

- **WHEN** the user looks at the stack
- **THEN** only the three bucket cards carry colour, and the colour each one carries is the one already used for that expiry status elsewhere in the app

#### Scenario: The stack reads as cards on a dark screen

- **WHEN** the user views the home screen in a dark colour scheme
- **THEN** every card, summary cards included, is distinguishable from the screen behind it and from the card it overlaps

#### Scenario: A summary card's contents stay readable in a light colour scheme

- **WHEN** the user brings forward the current-status or waste-statistics card while the device is in a light colour scheme
- **THEN** the chart, its legend, the waste rate and its counts are all readable, and none of them sits on a background of its own
