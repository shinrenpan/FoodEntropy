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