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

## MODIFIED Requirements

### Requirement: Read failures yield empty results and write failures fail loudly only in debug

The system SHALL return an empty collection when a fetch fails, without terminating the app.

When a save fails, the system SHALL raise a debug-build assertion **and** report the failure to its caller, so that each caller decides what to do. A caller that merely presents data MAY ignore the failure, because the unchanged interface already tells the user nothing happened. A caller that reports its own success to someone else — an assistant action speaking a confirmation, for instance — MUST NOT treat an ignored failure as success.

Re-reading after a failed save SHALL NOT be used to detect it: the context still reports the pending in-memory change, so the read appears to succeed.

#### Scenario: The store cannot be read

- **WHEN** a fetch fails at runtime
- **THEN** the caller receives an empty collection and the app continues running

#### Scenario: A save fails during development

- **WHEN** a save fails in a debug build
- **THEN** an assertion failure surfaces the problem immediately to the developer

#### Scenario: A save fails in a release build

- **WHEN** a save fails in a release build
- **THEN** the failure reaches the caller rather than being discarded, and the app continues running

#### Scenario: A screen ignores a failed save

- **WHEN** an in-app screen's write fails
- **THEN** the screen continues without an error of its own, because the list it shows is unchanged and conveys that nothing was recorded

## RENAMED Requirements

- FROM: `### Requirement: Read failures yield empty results and write failures fail loudly only in debug`
- TO: `### Requirement: Read failures yield empty results and write failures reach the caller`

