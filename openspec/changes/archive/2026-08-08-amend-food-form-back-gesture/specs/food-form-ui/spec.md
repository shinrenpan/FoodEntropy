## MODIFIED Requirements

### Requirement: Leaving with unsaved changes asks first, and leaving unchanged does not

The system SHALL compare the current field values against a snapshot taken when the form opened to decide whether changes exist, SHALL exclude presentation-only flags from that snapshot, SHALL ask for confirmation before discarding when changes exist, and SHALL leave immediately when they do not. This applies to the app's own back control; the system's interactive back gesture is covered separately.

#### Scenario: Backing out of an untouched form does not interrupt

- **WHEN** the user opens the form, changes nothing, and taps the app's back control
- **THEN** the form closes immediately with no prompt

#### Scenario: Backing out after editing asks

- **WHEN** the user changes a field and then taps the app's back control
- **THEN** a confirmation asks whether to discard the changes

#### Scenario: Choosing to keep editing preserves the work

- **WHEN** the user declines to discard
- **THEN** the form stays open with the changes intact, and the prompt itself does not count as a change

## ADDED Requirements

### Requirement: The system back gesture leaves without prompting, by design

The system SHALL allow the interactive back gesture to dismiss the form directly, without the discard confirmation, and SHALL NOT disable that gesture for this screen. The gesture-eligibility rule in `navigation` SHALL remain based on transition style alone, with no per-screen exception for the form.

#### Scenario: Swiping back discards unsaved changes silently

- **WHEN** the user has unsaved changes and performs the system edge-swipe back gesture
- **THEN** the form closes and the changes are lost, with no confirmation — the gesture is a system-level action whose outcome the user already expects

#### Scenario: The app's own control still asks

- **WHEN** the user has unsaved changes and instead taps the app's back control
- **THEN** the discard confirmation appears, because that control's meaning is defined by this app rather than by the system

#### Scenario: The router stays screen-agnostic

- **WHEN** the gesture-eligibility rule is evaluated for the form
- **THEN** it is decided by the arrival transition style alone, with no branch naming this screen
