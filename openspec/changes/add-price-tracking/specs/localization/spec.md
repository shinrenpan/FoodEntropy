## ADDED Requirements

### Requirement: Percentages are formatted by the system, like currency and dates

The system SHALL render percentages through a format style rather than appending a percent sign to a number, so that each language's symbol placement and spacing are handled by the system.

#### Scenario: A rate is shown in a language that places the symbol differently

- **WHEN** a percentage is displayed on a device whose language places the percent sign before the number, or separates it with a space
- **THEN** it follows that convention, because the app never assembles the string itself

---
### Requirement: Localised literals must appear directly inside the presenting call

The system SHALL write user-facing string literals directly inside the call that presents them, and SHALL NOT pass a localised string key through a variable or stored property before presenting it.

#### Scenario: A label taken from a value cannot be extracted

- **WHEN** a developer stores a localised string key in a property and presents it later
- **THEN** the compiler cannot confirm it is in use, the catalog marks the entry as unused, and anyone cleaning up by that signal deletes a translation that is still live

#### Scenario: A label written in place is recognised

- **WHEN** the literal is written directly in the presenting call
- **THEN** the build extracts it as a confirmed entry, and it is never reported as unused
