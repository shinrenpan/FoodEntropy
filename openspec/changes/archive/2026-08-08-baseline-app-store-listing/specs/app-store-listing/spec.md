## ADDED Requirements

### Requirement: The marketing URL is mandatory and its host must serve app-ads.txt

The system SHALL declare a marketing URL in every localisation of the store listing, and that URL's host SHALL be the domain serving the app-ads.txt file described by `advertising`.

#### Scenario: Verification succeeds when the chain is complete

- **WHEN** the marketing URL is declared and its host serves app-ads.txt containing this app's publisher entry
- **THEN** the ad network crawls that host and reports the file as verified

#### Scenario: An empty marketing URL reports as a missing file

- **WHEN** the marketing URL is absent
- **THEN** the ad network reports app-ads.txt as not found with an empty crawled-URL and no crawl timestamp — the signal that no host could be derived, not that the file is missing

#### Scenario: A mismatched host fails the same way

- **WHEN** the marketing URL points at a host that does not serve app-ads.txt
- **THEN** verification fails even though the file is published and reachable elsewhere

---
### Requirement: The listing's privacy policy is the same page the app links to

The system SHALL declare, as the store listing's privacy policy URL, the same URL the app opens from its settings screen.

#### Scenario: Both routes reach the same policy

- **WHEN** a user opens the privacy policy from within the app, and another reads it from the store page
- **THEN** both see the same document

---
### Requirement: Store copy claims nothing the shipped build cannot do

The system SHALL describe, in its description, promotional text, keywords, and screenshots, only capabilities present in the version being submitted.

#### Scenario: A planned feature is not advertised early

- **WHEN** a capability is on the roadmap but not in the submitted build
- **THEN** no listing field mentions or depicts it

#### Scenario: Screenshots match the shipped interface

- **WHEN** the interface changes between versions
- **THEN** the screenshots are updated to match what the submitted build actually shows

---
### Requirement: Privacy labels cover what bundled third-party SDKs collect

The system SHALL declare, in its privacy labels, the data collected by any third-party SDK it bundles, including the device identifiers the advertising SDK collects and the purpose for which they are used — not only the data the app itself collects.

#### Scenario: Advertising data collection is declared

- **WHEN** the app bundles an advertising SDK that collects device identifiers for third-party advertising
- **THEN** the privacy labels declare that collection and its purpose, even though the app stores no user data of its own off-device

#### Scenario: Upgrading the SDK triggers a re-check

- **WHEN** the advertising SDK is upgraded to a version that may collect differently
- **THEN** the privacy labels are re-verified against the new version before submission

---
### Requirement: Territory exclusions are compliance decisions with prerequisites

The system SHALL treat each excluded territory as carrying an unmet compliance obligation, and SHALL NOT add a territory until that obligation is satisfied.

#### Scenario: Adding a previously excluded region

- **WHEN** a decision is made to distribute in a territory that was excluded
- **THEN** the compliance work that motivated the exclusion — such as consent management for the advertising SDK — is completed first, rather than only changing the availability setting

---
### Requirement: Fields are chosen with their correction cost in mind

The system SHALL treat the marketing URL, description, keywords, and screenshots as version-bound — correctable only by submitting a new version — and the support URL, promotional text, and privacy policy URL as correctable at any time; and SHALL prefer the correctable fields for content likely to drift.

#### Scenario: A version-bound field cannot be fixed in place

- **WHEN** an omission or error is found in a version-bound field after the version is on sale
- **THEN** correcting it requires submitting a new version, so the field is verified before submission rather than after

#### Scenario: Drift-prone content goes where it can be fixed

- **WHEN** copy contains information likely to change, such as figures or time-sensitive statements
- **THEN** it is placed in a field that can be corrected without a submission
