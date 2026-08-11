## ADDED Requirements

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

---
### Requirement: An empty crawl record means the listing was never read

The system SHALL read the ad network's empty verification fields as evidence that the store listing has not been re-read, not as evidence that the file is missing or malformed.

#### Scenario: The console shows no URL and no crawl time

- **WHEN** both the app-ads.txt URL field and the last-crawled field are blank
- **THEN** no crawl has ever occurred, so inspecting the file is the wrong response — the file was never fetched, and the store listing association is what is missing

#### Scenario: The console shows a domain but reports a failure

- **WHEN** the URL field names the developer domain and the status still reports a problem
- **THEN** the crawl did happen and the fault is downstream — at that point the file's status code, content type, encoding, and trailing newline are what to check

---
### Requirement: Ad serving stays limited until the app itself is verified

The system SHALL expect ad requests to be served without revenue while the app is unverified, and SHALL NOT read that combination as an integration fault.

#### Scenario: Requests are counted but earnings stay at zero

- **WHEN** the console reports ad requests alongside zero estimated earnings and marks the app as needing review
- **THEN** the integration is working and the limit is administrative — it lifts when app verification and the eligibility review that follows it complete, not through changes to the ad code

---
### Requirement: Consent-platform obligations follow the territories on sale

The system SHALL determine whether a certified consent management platform is required from the territories the app is actually sold in, rather than from the ad network's generic prompt.

#### Scenario: The regions requiring consent are all excluded

- **WHEN** the app is on sale in no territory that mandates a certified consent platform
- **THEN** no such platform is configured, because the obligation does not attach to this listing

#### Scenario: The listing auto-enables future territories

- **WHEN** the listing is set to become available in territories added later
- **THEN** that setting is a standing exposure — a newly added territory can impose the consent obligation without any deliberate change to the listing, so it is reviewed whenever the ad configuration is revisited
