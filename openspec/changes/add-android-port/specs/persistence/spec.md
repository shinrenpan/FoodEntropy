## MODIFIED Requirements

### Requirement: The persistence layer never exposes its model type

The system SHALL convert every persisted entity to a domain model at the manager boundary, SHALL define that conversion on the entity itself, and SHALL NOT return, accept, or otherwise expose the persisted model type through the manager's public interface. This boundary SHALL hold for every storage implementation the app ships, so that the choice of storage technology is a platform-local decision invisible to all consumers.

#### Scenario: A view model requests the active list

- **WHEN** a view model asks the manager for the current food items
- **THEN** it receives domain values it can hold and compare freely, with no context-bound persistence objects among them

#### Scenario: A view model is tested without a database

- **WHEN** a unit test drives a view model with domain values injected directly
- **THEN** no store, container, or persisted entity is required for the test to run

#### Scenario: A second storage implementation backs the same boundary

- **WHEN** a platform stores its records through a different technology than the one used on iOS
- **THEN** it exposes the same method names and returns the same domain types, and no consumer above the boundary is aware of which implementation answered

## ADDED Requirements

### Requirement: Storage schema is defined once per implementation and mirrors the domain shape

The system SHALL define each storage implementation's schema in a single place, SHALL give it a column for every attribute the domain model carries, and SHALL persist the record status as the same raw string across implementations so that stored data is interpreted identically on every platform.

#### Scenario: A domain attribute is added

- **WHEN** the domain model gains an attribute
- **THEN** every storage implementation gains a corresponding column, additively, without rewriting existing records

#### Scenario: A status value is read back

- **WHEN** a record's status is read from any implementation
- **THEN** it maps to the same domain status, and an unrecognised value falls back to active exactly as it does on iOS

### Requirement: Photo storage adapts to the platform without changing the compression contract

The system SHALL downscale and compress a photo before storing it on every platform, using the same dimension limit and quality target, and SHALL allow the storage mechanism for the resulting bytes to differ per platform.

#### Scenario: A photo is attached on a platform without external storage support

- **WHEN** a photo is saved on a platform whose storage layer has no external-storage mechanism
- **THEN** the compressed bytes are stored inline, because they were already reduced to a size that makes inline storage acceptable

#### Scenario: Compression parameters are compared across platforms

- **WHEN** the same photo is attached on either platform
- **THEN** the stored bytes fall within the same size range, because the dimension limit and quality target are identical
