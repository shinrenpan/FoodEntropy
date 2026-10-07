## ADDED Requirements

### Requirement: Entitlement changes reach every visible screen

The system SHALL announce every change in the ad-removal entitlement, whatever caused it — a purchase, a restore, or a transaction update such as a refund or a purchase on another device — and every screen that shows entitlement-dependent content SHALL refresh when it is announced, rather than waiting to appear again. No announcement SHALL be made when a reconciliation leaves the entitlement unchanged.

#### Scenario: Buying ad removal while the home screen is beside settings

- **WHEN** the user completes the ad-removal purchase from the settings column while the home screen is shown in the other column
- **THEN** the ad slot disappears from the home screen immediately, without the user leaving or reopening either screen

#### Scenario: A refund arrives while the app is open

- **WHEN** a transaction update revokes the entitlement while the home screen is visible
- **THEN** the home screen refreshes and, by the rules in `advertising`, includes the ad slot again

#### Scenario: Reconciliation without a change is silent

- **WHEN** the app reconciles entitlements and the result matches the current state
- **THEN** no change is announced and no screen reloads because of it
