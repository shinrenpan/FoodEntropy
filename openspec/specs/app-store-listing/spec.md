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