# app-store-listing Specification

## Purpose

The only capability whose subject lives outside this repo: the App Store Connect fields that change how the app actually behaves. It deliberately keeps no local copy of the live values — a stale copy is worse than none, because it grants false confidence — so current state is always read from the API. The rule that earned this capability its existence: the ad network derives the host for app-ads.txt from the listing's marketing URL, so leaving that field empty reports as "file not found" no matter how correctly the file is published, and the empty crawled-URL column is the real signal. Correction cost is asymmetric and worth knowing before submission: support URL, promotional text, and the privacy policy URL are editable on a shipped version; marketing URL, description, keywords, and screenshots are not — `marketingUrl` returns `409 STATE_ERROR` once the version is on sale.

## Requirements

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



<!-- @trace
source: baseline-app-store-listing
updated: 2026-08-08
code:
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: The listing's privacy policy is the same page the app links to

The system SHALL declare, as the store listing's privacy policy URL, the same URL the app opens from its settings screen.

#### Scenario: Both routes reach the same policy

- **WHEN** a user opens the privacy policy from within the app, and another reads it from the store page
- **THEN** both see the same document

---



<!-- @trace
source: baseline-app-store-listing
updated: 2026-08-08
code:
  - Sources/Features/Settings/SettingsViewModel.swift
-->

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



<!-- @trace
source: baseline-app-store-listing
updated: 2026-08-08
code:
  - Sources/Features/Settings/SettingsViewModel.swift
-->

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



<!-- @trace
source: baseline-app-store-listing
updated: 2026-08-08
code:
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: Territory exclusions are compliance decisions with prerequisites

The system SHALL treat each excluded territory as carrying an unmet compliance obligation, and SHALL NOT add a territory until that obligation is satisfied.

#### Scenario: Adding a previously excluded region

- **WHEN** a decision is made to distribute in a territory that was excluded
- **THEN** the compliance work that motivated the exclusion — such as consent management for the advertising SDK — is completed first, rather than only changing the availability setting

---



<!-- @trace
source: baseline-app-store-listing
updated: 2026-08-08
code:
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: Fields are chosen with their correction cost in mind

The system SHALL treat the marketing URL, description, keywords, and screenshots as version-bound — correctable only by submitting a new version — and the support URL, promotional text, and privacy policy URL as correctable at any time; and SHALL prefer the correctable fields for content likely to drift.

#### Scenario: A version-bound field cannot be fixed in place

- **WHEN** an omission or error is found in a version-bound field after the version is on sale
- **THEN** correcting it requires submitting a new version, so the field is verified before submission rather than after

#### Scenario: Drift-prone content goes where it can be fixed

- **WHEN** copy contains information likely to change, such as figures or time-sensitive statements
- **THEN** it is placed in a field that can be corrected without a submission


<!-- @trace
source: baseline-app-store-listing
updated: 2026-08-08
code:
  - Sources/Features/Settings/SettingsViewModel.swift
-->

---
### Requirement: The ad-network file and the app's own pages are hosted separately by necessity

The system SHALL serve app-ads.txt from the developer site's domain root, and SHALL serve the app's own pages — landing page and privacy policy — from a path under that same domain. These two SHALL NOT be consolidated into a single location.

#### Scenario: The verification file cannot live under a path

- **WHEN** app-ads.txt is placed under a path rather than the domain root
- **THEN** the ad network cannot find it, because it fetches only from the root of the host derived from the marketing URL

#### Scenario: The marketing URL may point at a path

- **WHEN** the marketing URL points at the app's own page under a path on that domain
- **THEN** verification still succeeds, because only the host is taken from that URL and the path is ignored


<!-- @trace
source: consolidate-web-pages
updated: 2026-08-09
code: []
external:
  - shinrenpan.github.io:static/app-ads.txt
  - shinrenpan.github.io:static/FoodEntropy/
-->

---
### Requirement: Every app's pages live in the developer site repository

The system SHALL host each app's pages in the developer site's own repository, under a directory named for that app, rather than in the app's source repository.

#### Scenario: Finding where an app's privacy policy is maintained

- **WHEN** a privacy policy needs updating for any app
- **THEN** it is found in the developer site repository under that app's directory, following one rule rather than one rule per app

#### Scenario: The path segment is case-sensitive

- **WHEN** the directory name's capitalisation differs from the URL already declared in the App Store listing
- **THEN** the page returns not-found — the hosting platform matches path segments exactly, so the directory name must reproduce the declared URL's capitalisation

#### Scenario: A page served from the app's own repository takes precedence

- **WHEN** the app's source repository also publishes pages for the same path
- **THEN** that source wins over the developer site, so it must be disabled — and only after the new location is confirmed live, otherwise the privacy policy URL returns not-found in the interval, which is grounds for App Store rejection

<!-- @trace
source: consolidate-web-pages
updated: 2026-08-09
code: []
external:
  - shinrenpan.github.io:static/FoodEntropy/index.html
  - shinrenpan.github.io:static/FoodEntropy/privacy/index.html
-->

---
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

---
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

---
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
