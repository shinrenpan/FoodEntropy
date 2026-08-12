## ADDED Requirements

### Requirement: English is the source language and Traditional Chinese is the translation

The system SHALL use English as the String Catalog's source language, SHALL write user-facing literals in the code in English, SHALL declare English and Traditional Chinese as its supported localisations, and SHALL provide a Traditional Chinese translation for every catalog entry. English SHALL also be the language shown when the device's preferred languages match neither declared localisation.

Source language and fallback language SHALL be the same. When they differ, the source language has no compiled strings file of its own — its text reaches the screen only through the missing-translation path — and declaring a different fallback silently redirects its own users elsewhere.

#### Scenario: An English-speaking user sees English

- **WHEN** a user whose device language is English opens the app
- **THEN** every interface string appears in English

#### Scenario: A Traditional Chinese user sees Chinese

- **WHEN** a user whose preferred languages include Traditional Chinese opens the app
- **THEN** every interface string appears in Chinese, served from that language's own compiled strings file

#### Scenario: A user of an unsupported language

- **WHEN** a user whose preferred languages include neither declared localisation opens the app
- **THEN** the interface appears in English rather than in an unreadable language

#### Scenario: Currency and dates still follow the user's region

- **WHEN** the interface has fallen back to English for a user in a third region
- **THEN** amounts and dates remain formatted for that user's own locale — the fallback governs wording, not number formatting

---
### Requirement: A translated word is not reused across different meanings

The system SHALL give distinct user-facing meanings distinct catalog keys, even where one language would naturally use the same word for both.

An action and a state are different meanings. So are a chart label and a section heading. Merging them saves one entry and costs the ability to word them differently in any other language — a loss that only surfaces in the language that needed the distinction.

#### Scenario: One language merges what another separates

- **WHEN** two entries with different meanings would translate to the same word in the source language
- **THEN** they are given distinct keys, and the source-language wording is made specific enough to tell them apart

#### Scenario: A row action and a status share a word

- **WHEN** the same word would label both an action the user performs and a state an item is in
- **THEN** the action's key names the action, so that neither meaning is forced to follow the other's wording

## REMOVED Requirements

### Requirement: Traditional Chinese is the source language and English is the translation

**Reason**: The direction is reversed. Traditional Chinese as the source language left it without a compiled strings file of its own — its text reached the screen only through the missing-translation path — which made the fallback language and the source language impossible to set independently without silently breaking one of them.

**Migration**: Replaced by "English is the source language and Traditional Chinese is the translation". Chinese wording is unchanged throughout; it moves from being the key to being the translation. English wording is unchanged except for two entries deliberately split apart, recorded under "A translated word is not reused across different meanings".

### Requirement: The source language carries its own catalog entries

**Reason**: Its premise was that the source language differs from the fallback language, which held only while Traditional Chinese was the source and English the fallback. With both now English, the source language is served by the same compiled strings file as the fallback, and entries whose value equals their key serve no purpose.

**Migration**: The Traditional Chinese entries added under that requirement become ordinary translations — same values, no longer redundant-looking. Nothing needs deleting. The rule text is removed from the project instructions so that no future reader has to work out whether it still applies.
