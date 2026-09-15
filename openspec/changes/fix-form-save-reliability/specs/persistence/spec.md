## MODIFIED Requirements

### Requirement: Read failures yield empty results and write failures reach the caller

The system SHALL return an empty collection when a fetch fails, without terminating the app.

When a save fails, the system SHALL raise a debug-build assertion **and** report the failure to its caller, so that each caller decides what to do.

Whether a caller is permitted to ignore that failure SHALL be decided by one test: what the interface looks like afterwards.

- A caller whose interface stays visible and unchanged after a failed write SHALL be permitted to ignore the failure, because the unchanged interface already tells the user nothing happened.
- A caller that dismisses, closes, or replaces its own interface once a write succeeds SHALL NOT ignore the failure, because that dismissal is the app's signal that the write happened. Such a caller SHALL keep its interface in place and tell the user the write did not happen.
- A caller that reports its own success to someone else — an assistant action speaking a confirmation, for instance — SHALL NOT treat an ignored failure as success.

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

#### Scenario: A screen that stays put ignores a failed save

- **WHEN** a write fails on a screen that remains on display with the same content afterwards
- **THEN** the screen continues without an error of its own, because the unchanged content conveys that nothing was recorded

#### Scenario: A screen that closes on success cannot ignore a failed save

- **WHEN** a write fails on a screen that would have closed itself had the write succeeded
- **THEN** the screen stays open and reports the failure, because closing would tell the user the write happened

##### Example: applying the test to this app's writing callers

| Caller                              | Interface after a failed write | Ignoring permitted |
| ----------------------------------- | ------------------------------ | ------------------ |
| Item list row actions               | same list, item still present  | yes                |
| Item entry form                     | would have closed on success   | no                 |
| Assistant action spoken back to user | confirmation would be spoken  | no                 |
