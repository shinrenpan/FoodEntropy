## ADDED Requirements

### Requirement: The store is reachable from a process-level accessor

The system SHALL provide a single process-level accessor for the store within the app process, so that entry points without a connected scene reach the same store connection as the running interface. The app's scene SHALL obtain its store from that accessor rather than constructing its own. The accessor SHALL apply the existing sync preference and the existing layered fallback when it first constructs the store.

Within one app process there SHALL be exactly one such store connection, so that a write made by a scene-less entry point is visible to the interface without reopening the store.

#### Scenario: An action runs before any scene connects

- **WHEN** an assistant action performs while the app has no connected scene
- **THEN** it reaches the store through the process-level accessor and its write succeeds

#### Scenario: A scene-less write is visible to the interface

- **WHEN** an assistant action writes while the app is in the background, and the user then returns to the app
- **THEN** the interface shows the written result without the store being reopened

#### Scenario: The sync preference is honored once per launch

- **WHEN** the accessor constructs the store for the first time in a process
- **THEN** it reads the sync preference at that moment, preserving the rule that a changed preference applies on the next launch

#### Scenario: Store construction still degrades in layers

- **WHEN** the accessor constructs the store and the preferred configuration fails
- **THEN** it falls back through the same layers the app already applies, rather than failing the action
