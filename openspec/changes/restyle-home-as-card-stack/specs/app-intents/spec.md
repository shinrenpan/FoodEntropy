## MODIFIED Requirements

### Requirement: On-screen food items are annotated for assistant resolution

The system SHALL annotate each food row it displays with its entity identifier, so that an assistant capable of reading the screen can resolve a reference to what the user is looking at. The annotation SHALL NOT change any visual presentation, and SHALL NOT delay the system's request for the on-screen payload.

The annotation belongs to the rows themselves, wherever they are shown. A screen that shows summaries rather than rows SHALL carry no annotation, because it has no food item to name.

Whether the assistant actually resolves such a reference is outside this project's control and SHALL NOT be treated as an acceptance criterion: the capability reaches users only on a supported device, in a supported language, and in a supported region, and it was unavailable for this project's primary audience when the annotation shipped. The requirement covers only what the app provides.

#### Scenario: Annotation is attached to food rows only

- **WHEN** a screen renders food rows alongside anything that is not a food row
- **THEN** only the food rows carry an entity identifier, because elements that represent no food item cannot supply one and delay the payload request until it times out

#### Scenario: A screen of summaries carries no annotation

- **WHEN** the user is looking at a screen that shows only per-bucket summaries and statistics
- **THEN** nothing on it is annotated, since no single food item is on display

#### Scenario: The payload request completes within the system deadline

- **WHEN** the system requests the on-screen entity payload for a visible list of food rows
- **THEN** each row resolves without loading its stored photo, so the request completes before the deadline

#### Scenario: Annotation has no visual effect

- **WHEN** a list of food rows renders with annotations present
- **THEN** its layout and appearance are identical to the unannotated rendering
