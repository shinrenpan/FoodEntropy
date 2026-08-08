## ADDED Requirements

### Requirement: The ad-network file and the app's own pages are hosted separately by necessity

The system SHALL serve app-ads.txt from the developer site's domain root, and SHALL serve the app's own pages — landing page and privacy policy — from a path under that same domain. These two SHALL NOT be consolidated into a single location.

#### Scenario: The verification file cannot live under a path

- **WHEN** app-ads.txt is placed under a path rather than the domain root
- **THEN** the ad network cannot find it, because it fetches only from the root of the host derived from the marketing URL

#### Scenario: The marketing URL may point at a path

- **WHEN** the marketing URL points at the app's own page under a path on that domain
- **THEN** verification still succeeds, because only the host is taken from that URL and the path is ignored

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
