## ADDED Requirements

### Requirement: The store location is never specified explicitly once an app group is adopted

The system SHALL let the persistence framework determine the store's location from the app group entitlement alone, and SHALL NOT specify a configuration name, a file URL, or a group container identifier for that purpose.

This constraint exists because the framework's automatic copy of an existing store into the app group container is performed only when it detects the container itself. Naming or addressing the store explicitly bypasses that detection and opens a different, empty store, leaving every existing user's records unreachable at the previous location.

#### Scenario: An app group is introduced to a shipped app

- **WHEN** the app group entitlement is added and no store location is specified in code
- **THEN** the framework moves the existing records into the shared container, and users who upgrade keep their data

#### Scenario: A store location is specified to make the behaviour explicit

- **WHEN** a configuration name, file URL, or container identifier is specified so the location is predictable
- **THEN** an empty store is opened and existing records become unreachable — predictability here is bought with every upgrading user's data, so it SHALL NOT be done

#### Scenario: The automatic copy does not happen

- **WHEN** the copy fails or does not occur
- **THEN** the app continues against the records it can still reach rather than presenting an empty store as success, since sync is off by default and most users have no copy elsewhere

### Requirement: The store is reachable by every process that needs it

The system SHALL make the store reachable by both the app and any extension that reads it, by declaring the same app group on each. An extension SHALL open its own connection to that store rather than receiving one from the app.

#### Scenario: An extension reads the records

- **WHEN** an extension needs the current records
- **THEN** it opens the store through the shared app group, because processes cannot reach another process's private container

#### Scenario: An extension fails to open the store

- **WHEN** an extension cannot open or read the store
- **THEN** it presents its empty state and continues, applying the same principle as the app: a read failure yields empty results rather than a crash
