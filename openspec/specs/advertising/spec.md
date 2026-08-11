# advertising Specification

## Purpose

One 320x50 banner at the top of the home list — the app's only revenue source and only third-party dependency. Every choice here trades revenue for a minimal privacy footprint: non-personalised requests, no IDFA, no ATT prompt, EU excluded. The missing ATT prompt is deliberate and must not be "fixed": ATT is required only when tracking, and prompting without it risks rejection under Guideline 5.1.2. Two failure modes are silent — using the production ad unit during development is invalid traffic that can get the AdMob account suspended (hence the compile-time split), and app-ads.txt verification depends on a field outside this repo: the crawler derives the host to fetch from the App Store listing's marketing URL, so an empty marketing URL reports as "file not found" no matter how correctly the file is published.

## Requirements

### Requirement: Ad requests are non-personalised and the app never asks for tracking permission

The system SHALL mark every ad request as non-personalised, SHALL NOT access the advertising identifier, SHALL NOT present the app-tracking-transparency prompt, and SHALL NOT declare a tracking usage description.

#### Scenario: A user never sees a tracking prompt

- **WHEN** the user launches the app for the first time and browses screens that show ads
- **THEN** no tracking permission prompt appears at any point

#### Scenario: Ads are served without personalisation

- **WHEN** the app requests a banner
- **THEN** the request carries the non-personalised flag, so no cross-app profile is used to select the ad

---



<!-- @trace
source: baseline-advertising
updated: 2026-08-08
code:
  - Sources/Core/Ad/AdConfig.swift
  - Sources/Core/Ad/AdSlotView.swift
  - Sources/Core/Ad/BannerAdView.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/Home/HomeView.swift
  - project.yml
-->

---
### Requirement: Development builds must not use the production ad unit

The system SHALL resolve the banner ad unit identifier at compile time, using the ad network's official test unit in debug builds and the production unit only in release builds.

#### Scenario: A developer runs the app locally

- **WHEN** a debug build loads the home banner
- **THEN** it requests the official test ad unit, so development traffic is never attributed to the production unit

#### Scenario: A shipped build earns revenue

- **WHEN** a release build loads the home banner
- **THEN** it requests the production ad unit

---



<!-- @trace
source: baseline-advertising
updated: 2026-08-08
code:
  - Sources/Core/Ad/AdConfig.swift
  - Sources/Core/Ad/AdSlotView.swift
  - Sources/Core/Ad/BannerAdView.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/Home/HomeView.swift
  - project.yml
-->

---
### Requirement: The ad slot reserves space while loading and collapses only on failure

The system SHALL keep the ad slot at its banner height while a request is in flight and after a successful load, and SHALL collapse its height, padding, and background to nothing when the request fails or returns no ad.

#### Scenario: No ad is available

- **WHEN** the banner request returns no fill or fails
- **THEN** the slot disappears entirely, leaving no empty frame or gap at the top of the list

#### Scenario: A slow load still has room to arrive

- **WHEN** the banner is still loading
- **THEN** the slot retains its height, so the banner has a non-zero area to render into once it arrives

---



<!-- @trace
source: baseline-advertising
updated: 2026-08-08
code:
  - Sources/Core/Ad/AdConfig.swift
  - Sources/Core/Ad/AdSlotView.swift
  - Sources/Core/Ad/BannerAdView.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/Home/HomeView.swift
  - project.yml
-->

---
### Requirement: The ad slot is opaque and labelled once an ad is present

The system SHALL give the ad slot an opaque background so list content cannot show through it while scrolling, and SHALL display an "ad" label only after an ad has successfully loaded.

#### Scenario: Scrolling the list under the pinned slot

- **WHEN** the user scrolls the food list while a banner is displayed at the top
- **THEN** the list content passes behind the slot without showing through it

#### Scenario: No label is shown over empty space

- **WHEN** the slot is still loading or has collapsed
- **THEN** no "ad" label is displayed

---



<!-- @trace
source: baseline-advertising
updated: 2026-08-08
code:
  - Sources/Core/Ad/AdConfig.swift
  - Sources/Core/Ad/AdSlotView.swift
  - Sources/Core/Ad/BannerAdView.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/Home/HomeView.swift
  - project.yml
-->

---
### Requirement: Purchasing ad removal prevents the slot from being created at all

The system SHALL have the presenting screen decide whether to include the ad slot based on the ad-removal entitlement, and the slot itself SHALL contain no purchase-related logic.

#### Scenario: A paying user makes no ad requests

- **WHEN** a user holding the ad-removal entitlement views the home screen
- **THEN** the ad slot is not created and no ad request is sent, rather than a request being made and its result hidden

#### Scenario: The slot stays unaware of purchases

- **WHEN** the ad slot renders
- **THEN** it decides its own layout solely from the load result, with no knowledge of the purchase state

---



<!-- @trace
source: baseline-advertising
updated: 2026-08-08
code:
  - Sources/Core/Ad/AdConfig.swift
  - Sources/Core/Ad/AdSlotView.swift
  - Sources/Core/Ad/BannerAdView.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/Home/HomeView.swift
  - project.yml
-->

---
### Requirement: app-ads.txt verification depends on the store listing's marketing URL

The system SHALL publish an app-ads.txt file containing this app's publisher entry at the root of the developer website, and that website's host SHALL be the one declared in the App Store listing's marketing URL, because the ad network derives the host to crawl from that field rather than from the app itself.

#### Scenario: The marketing URL is absent

- **WHEN** the store listing has no marketing URL
- **THEN** the ad network cannot derive a host to crawl, and app-ads.txt is reported as not found even though the file is published and publicly reachable

#### Scenario: The chain is complete

- **WHEN** the marketing URL is present and its host serves app-ads.txt containing the publisher entry
- **THEN** the ad network can crawl and verify the file


<!-- @trace
source: baseline-advertising
updated: 2026-08-08
code:
  - Sources/Core/Ad/AdConfig.swift
  - Sources/Core/Ad/AdSlotView.swift
  - Sources/Core/Ad/BannerAdView.swift
  - Sources/App/AppDelegate.swift
  - Sources/Features/Home/HomeView.swift
  - project.yml
-->

---
### Requirement: Verification is triggered by the publisher, not awaited

The system SHALL treat ad-network verification as an action the publisher initiates from the ad network's console once the store listing is complete, rather than as an outcome that arrives on its own. Waiting SHALL NOT be the response to a verification that has not happened.

#### Scenario: Every prerequisite is satisfied but nothing happens

- **WHEN** the marketing URL is live, the store page carries the developer website link, and app-ads.txt is reachable, yet the console still reports the file as not found
- **THEN** the remaining step is to run the console's verify-app action — the ad network does not re-read the store listing on its own schedule in any useful timeframe

#### Scenario: The first attempt reports the stale state

- **WHEN** the verify-app action is run and fails with the same message as before
- **THEN** it is run a second time, because the first invocation reports the cached snapshot while requesting a refresh, and only the next one sees the refreshed data — a single failure is not evidence that the action does not work

#### Scenario: Deciding whether the delay is ours or theirs

- **WHEN** verification has not completed and the cause is unclear
- **THEN** the store page's own markup is checked for a developer-website link carrying the developer link type — if it is present, every input under this project's control is correct and the gap is on the ad network's side, so further changes here would be guesswork


<!-- @trace
source: add-marketing-url
updated: 2026-08-11
code: []
ops:
  - App Store Connect: appStoreVersionLocalizations.marketingUrl
  - AdMob console: 應用程式 → 驗證應用程式 / app-ads.txt
  - shinrenpan.github.io:static/app-ads.txt
-->

---
### Requirement: An empty crawl record means the listing was never read

The system SHALL read the ad network's empty verification fields as evidence that the store listing has not been re-read, not as evidence that the file is missing or malformed.

#### Scenario: The console shows no URL and no crawl time

- **WHEN** both the app-ads.txt URL field and the last-crawled field are blank
- **THEN** no crawl has ever occurred, so inspecting the file is the wrong response — the file was never fetched, and the store listing association is what is missing

#### Scenario: The console shows a domain but reports a failure

- **WHEN** the URL field names the developer domain and the status still reports a problem
- **THEN** the crawl did happen and the fault is downstream — at that point the file's status code, content type, encoding, and trailing newline are what to check


<!-- @trace
source: add-marketing-url
updated: 2026-08-11
code: []
ops:
  - App Store Connect: appStoreVersionLocalizations.marketingUrl
  - AdMob console: 應用程式 → 驗證應用程式 / app-ads.txt
  - shinrenpan.github.io:static/app-ads.txt
-->

---
### Requirement: Ad serving stays limited until the app itself is verified

The system SHALL expect ad requests to be served without revenue while the app is unverified, and SHALL NOT read that combination as an integration fault.

#### Scenario: Requests are counted but earnings stay at zero

- **WHEN** the console reports ad requests alongside zero estimated earnings and marks the app as needing review
- **THEN** the integration is working and the limit is administrative — it lifts when app verification and the eligibility review that follows it complete, not through changes to the ad code


<!-- @trace
source: add-marketing-url
updated: 2026-08-11
code: []
ops:
  - App Store Connect: appStoreVersionLocalizations.marketingUrl
  - AdMob console: 應用程式 → 驗證應用程式 / app-ads.txt
  - shinrenpan.github.io:static/app-ads.txt
-->

---
### Requirement: Consent-platform obligations follow the territories on sale

The system SHALL determine whether a certified consent management platform is required from the territories the app is actually sold in, rather than from the ad network's generic prompt.

#### Scenario: The regions requiring consent are all excluded

- **WHEN** the app is on sale in no territory that mandates a certified consent platform
- **THEN** no such platform is configured, because the obligation does not attach to this listing

#### Scenario: The listing auto-enables future territories

- **WHEN** the listing is set to become available in territories added later
- **THEN** that setting is a standing exposure — a newly added territory can impose the consent obligation without any deliberate change to the listing, so it is reviewed whenever the ad configuration is revisited

<!-- @trace
source: add-marketing-url
updated: 2026-08-11
code: []
ops:
  - App Store Connect: appStoreVersionLocalizations.marketingUrl
  - AdMob console: 應用程式 → 驗證應用程式 / app-ads.txt
  - shinrenpan.github.io:static/app-ads.txt
-->