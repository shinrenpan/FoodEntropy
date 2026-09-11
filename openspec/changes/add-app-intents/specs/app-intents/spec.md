## ADDED Requirements

### Requirement: Core food actions run without opening the app

The system SHALL expose adding a food item, marking one consumed, marking one wasted, and extending one's expiry date as actions that complete without bringing the app to the foreground. Each action SHALL delegate to the existing persistence operations rather than reimplementing the write.

#### Scenario: An action runs while the app is not running

- **WHEN** the user runs the "mark consumed" action from Shortcuts while the app is not running
- **THEN** the item's stored status changes to consumed and the app is not brought to the foreground

#### Scenario: An action's result matches in-app behavior

- **WHEN** the user adds a food item through the action with a name and an expiry date
- **THEN** the resulting record is indistinguishable from one created inside the app, including its resolution time being unset and its status being active

#### Scenario: Extending an expiry preserves the other stored values

- **WHEN** the user extends an item's expiry date through the action
- **THEN** the item's name, purchase date, photo, and recorded cost are unchanged

##### Example: extending does not clear the cost

- **GIVEN** an item named "Milk" with expiryDate=2026-09-20, price=89.0, and a stored photo
- **WHEN** the extend action sets expiryDate=2026-09-27
- **THEN** the stored item has expiryDate=2026-09-27, price=89.0, and its photo intact

### Requirement: Food items are exposed as an app entity with a stable identifier

The system SHALL expose a food item as an assistant-visible entity whose identifier is the item's existing persistent identifier. The entity SHALL carry the item's name, purchase date, expiry date, recorded cost, and its expiry status computed on read. The entity type SHALL NOT hold the persistence model type.

#### Scenario: The entity identifier survives a restart

- **WHEN** an entity identifier captured in one app launch is resolved in a later launch
- **THEN** it resolves to the same food item

#### Scenario: Expiry status is computed, never stored

- **WHEN** the entity reports an item's expiry status
- **THEN** the value is derived from the expiry date against the current date, and no expiry status is persisted

### Requirement: Entity queries resolve by identifier, by name, and by suggestion

The system SHALL resolve entities by identifier, SHALL filter entities by a name string supplied by the caller, and SHALL offer the currently active items as suggestions when no criteria are supplied.

#### Scenario: Resolving a deleted item

- **WHEN** a query resolves an identifier whose item has been deleted
- **THEN** the query returns no entity for that identifier

#### Scenario: Suggestions exclude resolved items

- **WHEN** the system asks for suggested entities
- **THEN** only items whose stored status is active are offered

##### Example: name filtering is case-insensitive and partial

| Stored items | Filter string | Result |
| ------------ | ------------- | ------ |
| Milk, Milk Chocolate, Bread | "milk" | Milk, Milk Chocolate |
| Milk, Bread | "MILK" | Milk |
| Milk, Bread | "cheese" | (none) |

### Requirement: Opening a food item by voice is available on iOS 27

On iOS 27 and later the system SHALL expose an open action that the assistant can invoke by natural language. On earlier versions that action SHALL be absent, and every other action SHALL remain available.

The system SHALL NOT claim in-app search as an assistant capability. Finding food items is exposed as an ordinary action that returns its matches, usable from Shortcuts and Spotlight on every supported version; it carries no schema, so the assistant reaches it only through the app's stated phrases, not through free-form search requests.

#### Scenario: Opening an item by voice on iOS 27

- **WHEN** the user asks the assistant to open a named food item
- **THEN** the app is brought to the foreground showing the home destination

#### Scenario: Finding items returns matches rather than presenting them

- **WHEN** the find action runs with a name fragment
- **THEN** it returns the matching active items as values to its caller, and the app is not brought to the foreground

#### Scenario: Running on iOS 26

- **WHEN** the app runs on iOS 26
- **THEN** every action except the open action is available in Shortcuts, without any error or degraded-mode message

### Requirement: Food items are indexed for Spotlight

The system SHALL index active food items so they are findable in Spotlight by name, and SHALL keep that index current whenever stored data changes.

#### Scenario: A newly added item becomes findable

- **WHEN** a food item is added by any path
- **THEN** it becomes findable in Spotlight by its name

#### Scenario: A resolved item stops being offered

- **WHEN** an item is marked consumed, marked wasted, or deleted
- **THEN** it is no longer offered as an active food item in Spotlight

### Requirement: On-screen food items are annotated for assistant resolution

The system SHALL annotate each food row on the home list with its entity identifier, so that an assistant capable of reading the screen can resolve a reference to what the user is looking at. The annotation SHALL NOT change any visual presentation, and SHALL NOT delay the system's request for the on-screen payload.

Whether the assistant actually resolves such a reference is outside this project's control and SHALL NOT be treated as an acceptance criterion: the capability reaches users only on a supported device, in a supported language, and in a supported region, and it was unavailable for this project's primary audience when the annotation shipped. The requirement covers only what the app provides.

#### Scenario: Annotation is attached to food rows only

- **WHEN** the home list renders its summary chart, its waste statistics, and its food rows
- **THEN** only the food rows carry an entity identifier, because rows that represent no food item cannot supply one and delay the payload request until it times out

#### Scenario: The payload request completes within the system deadline

- **WHEN** the system requests the on-screen entity payload for a visible list of food rows
- **THEN** each row resolves without loading its stored photo, so the request completes before the deadline

#### Scenario: Annotation has no visual effect

- **WHEN** the home list renders with annotations present
- **THEN** its layout and appearance are identical to the unannotated rendering

### Requirement: Assistant phrases and action titles are localized

The system SHALL route every user-visible action title, parameter summary, and spoken phrase through the string catalog, with English as the source language and a Traditional Chinese translation present for each. Each spoken phrase SHALL include the application name token.

#### Scenario: Phrases exist for both languages

- **WHEN** the shortcut phrases are collected for English and for Traditional Chinese
- **THEN** each language has at least one phrase per exposed action

#### Scenario: No hardcoded user-visible string

- **WHEN** the string catalog is inspected after a build
- **THEN** it contains no stale entries and no entry missing its Traditional Chinese translation

### Requirement: Actions fail loudly when the target no longer exists

The system SHALL surface an error when an action names a food item that no longer exists or has already left the active list, rather than reporting success. The error message SHALL be localized.

#### Scenario: Acting on a deleted item

- **WHEN** an action targets a food item that has been deleted
- **THEN** the action reports a localized error and no write occurs

#### Scenario: Acting on an already-resolved item

- **WHEN** an action marks an item consumed that was already marked wasted
- **THEN** the action reports a localized error rather than silently succeeding
