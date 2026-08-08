# localization Specification

## Purpose

The String Catalog conventions, running the uncommon direction: Traditional Chinese is the source language and English is the translation, because the product's copy is authored in Chinese and its primary market reads it. Two boundaries matter more than the rule itself. First, the syntax differs by layer — a literal in a view is extracted automatically, the same sentence in a view model is not unless explicitly wrapped, and a miss there produces no build warning, only a string that is never translated. Second, three categories stay out of the catalog on purpose: developer diagnostics (translating them makes errors unsearchable and machine-dependent), debug-only fixtures (absent from release builds entirely), and URL scheme strings (translating one breaks routing).

## Requirements

### Requirement: Traditional Chinese is the source language and English is the translation

The system SHALL use Traditional Chinese as the String Catalog's source language, SHALL declare Traditional Chinese and English as its supported localisations, and SHALL provide an English translation for every catalog entry.

#### Scenario: An English-speaking user sees English

- **WHEN** a user whose device language is English opens the app
- **THEN** every interface string appears in English

#### Scenario: A user of an unsupported language

- **WHEN** a user whose device language is neither declared localisation opens the app
- **THEN** the interface appears in the source language

---



<!-- @trace
source: baseline-localization
updated: 2026-08-08
code:
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/InfoPlist.xcstrings
  - project.yml
-->

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



<!-- @trace
source: baseline-localization
updated: 2026-08-08
code:
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/InfoPlist.xcstrings
  - project.yml
-->

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



<!-- @trace
source: baseline-localization
updated: 2026-08-08
code:
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/InfoPlist.xcstrings
  - project.yml
-->

---
### Requirement: Currency and dates are formatted by the system, not assembled by the app

The system SHALL display prices using the store's own localised display price, SHALL format dates and numbers through system formatting, and SHALL NOT assemble currency or date strings itself.

#### Scenario: A price in the user's region

- **WHEN** a user in any storefront views the purchase row
- **THEN** the price appears with that region's currency symbol, separators, and placement, without the app composing the string

---



<!-- @trace
source: baseline-localization
updated: 2026-08-08
code:
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/InfoPlist.xcstrings
  - project.yml
-->

---
### Requirement: User-entered content is never translated

The system SHALL present user-entered content such as food names exactly as entered, including when it is embedded in a localised sentence.

#### Scenario: A notification names the item

- **WHEN** an expiry notification is delivered for an item the user named in their own words
- **THEN** the surrounding sentence follows the device language while the name itself is unchanged

---



<!-- @trace
source: baseline-localization
updated: 2026-08-08
code:
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/InfoPlist.xcstrings
  - project.yml
-->

---
### Requirement: Diagnostics, debug fixtures, and protocol strings stay out of the catalog

The system SHALL NOT localise developer diagnostic messages, fixture data that exists only in debug builds, or URL scheme and deeplink strings.

#### Scenario: An assertion message stays searchable

- **WHEN** a developer hits an assertion failure
- **THEN** the message text is the same regardless of the machine's language, so it can be found by searching the source

#### Scenario: A deeplink keeps working in every language

- **WHEN** the app handles a deeplink
- **THEN** the scheme and host are matched against fixed strings that no translation can alter


<!-- @trace
source: baseline-localization
updated: 2026-08-08
code:
  - Sources/Resources/Localizable.xcstrings
  - Sources/Resources/InfoPlist.xcstrings
  - project.yml
-->

---
### Requirement: Percentages are formatted by the system, like currency and dates

The system SHALL render percentages through a format style rather than appending a percent sign to a number, so that each language's symbol placement and spacing are handled by the system.

#### Scenario: A rate is shown in a language that places the symbol differently

- **WHEN** a percentage is displayed on a device whose language places the percent sign before the number, or separates it with a space
- **THEN** it follows that convention, because the app never assembles the string itself


<!-- @trace
source: add-price-tracking
updated: 2026-08-08
code:
  - Sources/Features/FoodForm/FoodFormViewModel+Models.swift
  - Tests/FoodEntropyTests/CurrencyFormatTests.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - CLAUDE.md
  - Sources/Features/Home/HomeView.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Core/Extensions/CurrencyFormat.swift
  - Tests/FoodEntropyTests/FoodFormViewModelTests.swift
  - Sources/Core/Components/FoodRowView.swift
  - Sources/Core/Domain/FoodItem.swift
  - Tests/FoodEntropyTests/SwiftDataManagerTests.swift
  - Sources/Core/Domain/FoodItemMocks.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/FoodForm/FoodFormView.swift
  - README.md
  - Sources/Features/Home/HomeViewModel.swift
  - Tests/FoodEntropyTests/HomeViewModelTests.swift
-->

---
### Requirement: Localised literals must appear directly inside the presenting call

The system SHALL write user-facing string literals directly inside the call that presents them, and SHALL NOT pass a localised string key through a variable or stored property before presenting it.

#### Scenario: A label taken from a value cannot be extracted

- **WHEN** a developer stores a localised string key in a property and presents it later
- **THEN** the compiler cannot confirm it is in use, the catalog marks the entry as unused, and anyone cleaning up by that signal deletes a translation that is still live

#### Scenario: A label written in place is recognised

- **WHEN** the literal is written directly in the presenting call
- **THEN** the build extracts it as a confirmed entry, and it is never reported as unused

<!-- @trace
source: add-price-tracking
updated: 2026-08-08
code:
  - Sources/Features/FoodForm/FoodFormViewModel+Models.swift
  - Tests/FoodEntropyTests/CurrencyFormatTests.swift
  - Sources/Features/Home/HomeViewModel+Models.swift
  - CLAUDE.md
  - Sources/Features/Home/HomeView.swift
  - Sources/Core/Persistence/SwiftDataManager.swift
  - Sources/Core/Persistence/FoodItemEntity.swift
  - Sources/App/SceneDelegate.swift
  - Sources/Core/Extensions/CurrencyFormat.swift
  - Tests/FoodEntropyTests/FoodFormViewModelTests.swift
  - Sources/Core/Components/FoodRowView.swift
  - Sources/Core/Domain/FoodItem.swift
  - Tests/FoodEntropyTests/SwiftDataManagerTests.swift
  - Sources/Core/Domain/FoodItemMocks.swift
  - Sources/Features/FoodForm/FoodFormViewModel.swift
  - Sources/Resources/Localizable.xcstrings
  - Sources/Features/FoodForm/FoodFormView.swift
  - README.md
  - Sources/Features/Home/HomeViewModel.swift
  - Tests/FoodEntropyTests/HomeViewModelTests.swift
-->