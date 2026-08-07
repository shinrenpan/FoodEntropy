## ADDED Requirements

### Requirement: Traditional Chinese is the source language and English is the translation

The system SHALL use Traditional Chinese as the String Catalog's source language, SHALL declare Traditional Chinese and English as its supported localisations, and SHALL provide an English translation for every catalog entry.

#### Scenario: An English-speaking user sees English

- **WHEN** a user whose device language is English opens the app
- **THEN** every interface string appears in English

#### Scenario: A user of an unsupported language

- **WHEN** a user whose device language is neither declared localisation opens the app
- **THEN** the interface appears in the source language

---
### Requirement: User-facing strings reach the catalog, and the required syntax differs by layer

The system SHALL route every user-facing string through the String Catalog: written as a literal where the surrounding API accepts a localised string key, and explicitly wrapped as a localised string everywhere else. Domain types SHALL NOT carry user-facing text.

#### Scenario: A string added in a view is translated

- **WHEN** a developer adds a label in a view using a literal in a position that takes a localised string key
- **THEN** the build extracts it into the catalog for translation

#### Scenario: A string added outside a view is translated

- **WHEN** a developer adds user-facing text in a view model or service
- **THEN** it is explicitly wrapped as a localised string, since a plain string there would never be extracted

---
### Requirement: System-presented strings are localised in their own catalog

The system SHALL localise the app's display name and its camera and photo library permission descriptions in a dedicated Info.plist string catalog, in both supported languages.

#### Scenario: The permission prompt matches the device language

- **WHEN** an English-speaking user is asked for camera or photo library access
- **THEN** the explanation appears in English

#### Scenario: The app name matches the device language

- **WHEN** the device language changes between the supported languages
- **THEN** the name shown under the home screen icon follows

---
### Requirement: Currency and dates are formatted by the system, not assembled by the app

The system SHALL display prices using the store's own localised display price, SHALL format dates and numbers through system formatting, and SHALL NOT assemble currency or date strings itself.

#### Scenario: A price in the user's region

- **WHEN** a user in any storefront views the purchase row
- **THEN** the price appears with that region's currency symbol, separators, and placement, without the app composing the string

---
### Requirement: User-entered content is never translated

The system SHALL present user-entered content such as food names exactly as entered, including when it is embedded in a localised sentence.

#### Scenario: A notification names the item

- **WHEN** an expiry notification is delivered for an item the user named in their own words
- **THEN** the surrounding sentence follows the device language while the name itself is unchanged

---
### Requirement: Diagnostics, debug fixtures, and protocol strings stay out of the catalog

The system SHALL NOT localise developer diagnostic messages, fixture data that exists only in debug builds, or URL scheme and deeplink strings.

#### Scenario: An assertion message stays searchable

- **WHEN** a developer hits an assertion failure
- **THEN** the message text is the same regardless of the machine's language, so it can be found by searching the source

#### Scenario: A deeplink keeps working in every language

- **WHEN** the app handles a deeplink
- **THEN** the scheme and host are matched against fixed strings that no translation can alter
