## ADDED Requirements

### Requirement: The export toolchain resolves to the system copy utility

The system SHALL ensure the copy utility invoked during archive export resolves to the operating system's own build rather than a package-manager installation, before starting an upload.

The failure this prevents is unusually opaque: the export halts with a message naming only the act of copying, with no file, command, or utility named. Nothing identifies the utility as the cause, so the natural next step — inspecting the archive, the signing, or the network — investigates the wrong layer entirely.

#### Scenario: An export stops at the copying stage

- **WHEN** an export fails with a message that refers only to copying, without naming a file or a command
- **THEN** the copy utility's resolution order is checked first, before the archive or the signing is examined

#### Scenario: A package-manager build shadows the system one

- **WHEN** a package-manager build of the copy utility precedes the system one in the executable search path
- **THEN** it is taken out of that path for the duration of the upload and restored afterwards, since its arguments are not interchangeable with the system build's

#### Scenario: The same failure recurs across releases

- **WHEN** this failure has occurred in a previous release
- **THEN** the check is part of the pre-upload routine rather than something rediscovered each time — the message gives no clue on its own, so recall is the only thing that shortens it

### Requirement: Changing an identifier's capabilities invalidates its distribution profile

The system SHALL regenerate the distribution provisioning profile after any capability is added to an app identifier, and SHALL treat a successful device build as no evidence that distribution will succeed.

Development and distribution profiles are refreshed by different mechanisms. The development one is rebuilt automatically during a device build, so a capability added for a new feature appears to work immediately. The distribution one is not, and an extension's identifier may never have had one at all — its device testing having run entirely on development profiles.

#### Scenario: A capability is added for a new feature

- **WHEN** an identifier gains a capability and the feature is verified on a device
- **THEN** the distribution profile is still regarded as stale, because that verification exercised only the development profile

#### Scenario: An extension is introduced

- **WHEN** an app gains an extension with its own identifier
- **THEN** that identifier needs its own distribution profile, which no amount of device testing will have created

#### Scenario: Automated signing lacks the authority

- **WHEN** an automated credential is used to regenerate profiles during an export
- **THEN** it fails for want of signing authority, and the distribute step is performed through the development environment's own interface instead, which acts as the account holder rather than as that credential

### Requirement: Demonstration data is regenerated immediately before capturing screenshots

The system SHALL regenerate its demonstration data immediately before store screenshots are captured, because that data's dates are relative to the moment it was seeded and decay into a uniformly expired state as time passes.

#### Scenario: Data seeded on an earlier day is reused

- **WHEN** screenshots are captured against demonstration data seeded days earlier
- **THEN** items intended to span every expiry state have all reached the expired one, and the composition the screenshots were meant to show no longer exists

#### Scenario: A conditional element disappears from the capture

- **WHEN** every item has expired
- **THEN** anything shown only for items still ahead of their expiry — the upcoming-cost line among them — renders nothing at all, silently removing from the screenshot the very thing it was meant to advertise

#### Scenario: Seeding is skipped because data already exists

- **WHEN** demonstration data is seeded into a store that is not empty
- **THEN** nothing is written and the stale data survives, so the store is cleared first rather than relying on the seeding step to refresh it
