## MODIFIED Requirements

### Requirement: Traditional Chinese is the source language and English is the translation

The system SHALL use Traditional Chinese as the String Catalog's source language, SHALL declare Traditional Chinese and English as its supported localisations, and SHALL provide an English translation for every catalog entry. English SHALL also be the language shown when the device's preferred languages match neither declared localisation, because it is the only one of the two with international reach.

#### Scenario: An English-speaking user sees English

- **WHEN** a user whose device language is English opens the app
- **THEN** every interface string appears in English

#### Scenario: A user of an unsupported language

- **WHEN** a user whose preferred languages include neither declared localisation opens the app
- **THEN** the interface appears in English rather than in the source language, since an unreadable interface serves that user no better than no translation at all

#### Scenario: Currency and dates still follow the user's region

- **WHEN** the interface has fallen back to English for a user in a third region
- **THEN** amounts and dates remain formatted for that user's own locale — the fallback governs wording, not number formatting

## ADDED Requirements

### Requirement: The source language carries its own catalog entries

The system SHALL give every catalog entry an explicit entry for the source language, with the same value as its key, rather than relying on the key itself being displayed when no translation is found.

This looks redundant and is not. Without those entries the source language has no compiled strings file at all, and its text reaches the screen only through the missing-translation path. Once another language is declared as the fallback, that path stops leading to the source language — and every source-language user silently receives the fallback instead.

#### Scenario: Entries for the source language appear redundant during cleanup

- **WHEN** entries whose value equals their key are reviewed as candidates for removal
- **THEN** they are kept, because deleting them removes the source language's compiled strings file and its users fall through to the fallback language

#### Scenario: The failure is silent

- **WHEN** the source language's entries are missing
- **THEN** the build still succeeds and no warning is produced — the defect surfaces only as the wrong language on screen, so it SHALL be caught by declaring the entries rather than by review

#### Scenario: A new user-facing string is added

- **WHEN** a string is added and the catalog gains a new entry
- **THEN** it receives entries for both the source language and the translation before the work is considered complete
