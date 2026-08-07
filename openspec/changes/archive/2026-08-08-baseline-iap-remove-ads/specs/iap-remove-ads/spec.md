## ADDED Requirements

### Requirement: Ownership is derived from StoreKit entitlements and never stored locally

The system SHALL determine whether ads are removed by inspecting the user's current StoreKit entitlements for the remove-ads product with no revocation date, and SHALL NOT persist a purchased flag in user defaults, the database, or any other local storage.

#### Scenario: A refunded purchase stops granting the benefit

- **WHEN** the user's purchase is refunded or revoked and the app reconciles entitlements
- **THEN** the ad-removed state returns to false and ads are shown again

#### Scenario: A revoked entitlement still present in the list is not honoured

- **WHEN** the entitlement list contains a transaction for the product that carries a revocation date
- **THEN** it does not count as ownership

#### Scenario: Ownership follows the Apple ID to a new device

- **WHEN** the user installs the app on another device signed in to the same Apple ID
- **THEN** the ad-removed state is restored without the user tapping restore

---
### Requirement: The app reconciles at launch and listens for transaction updates

The system SHALL, at launch, register a listener for transaction updates, load the product, and reconcile entitlements; and SHALL register that listener at most once per session.

#### Scenario: A purchase made elsewhere is picked up on next launch

- **WHEN** the user purchased on another device and then launches this one
- **THEN** the launch reconciliation reports ownership and ads are not shown

#### Scenario: A refund during a session takes effect without a restart

- **WHEN** a refund is processed while the app is running
- **THEN** the update listener reconciles entitlements and the app reflects the loss of ownership

#### Scenario: Repeated start calls do not stack listeners

- **WHEN** the start routine runs while a listener is already registered
- **THEN** no second listener is created, so each transaction is handled once

---
### Requirement: A purchase counts only when verified, and must be finished

The system SHALL treat a purchase as successful only when the result is a success carrying a verified transaction, SHALL finish that transaction, and SHALL then re-derive ownership from entitlements rather than setting it directly. A cancelled or pending result SHALL report no ownership.

#### Scenario: The user cancels the purchase sheet

- **WHEN** the user dismisses the system purchase sheet without buying
- **THEN** the state remains not purchased and no error is presented

#### Scenario: A purchase awaiting approval is not yet ownership

- **WHEN** the purchase result is pending, such as when it awaits a parent's approval
- **THEN** the app reports no ownership for now, and picks the purchase up through the update listener once it is approved

#### Scenario: A completed purchase removes ads

- **WHEN** the user completes a verified purchase
- **THEN** the transaction is finished, entitlements are re-derived, and ads disappear

---
### Requirement: A restore control is offered even though entitlements usually make it unnecessary

The system SHALL provide a restore action that synchronises with the App Store and then re-derives ownership from entitlements.

#### Scenario: Restore recovers a purchase that failed to appear

- **WHEN** a user who has purchased sees ads and taps restore
- **THEN** the app synchronises with the App Store, re-derives ownership, and hides the ads if the entitlement is present

---
### Requirement: Purchase and restore cannot be triggered concurrently

The system SHALL block further purchase or restore attempts while one is already in progress.

#### Scenario: Repeated taps during a purchase

- **WHEN** the user taps the purchase row repeatedly while the system sheet is being presented
- **THEN** only one purchase flow runs

#### Scenario: Restore tapped during a purchase

- **WHEN** the user taps restore while a purchase is in progress
- **THEN** the restore does not start

---
### Requirement: Purchase is unavailable when the product could not be loaded

The system SHALL report no ownership change when a purchase is attempted without a loaded product, and SHALL present no price when the product is unavailable.

#### Scenario: The product list could not be fetched

- **WHEN** product loading fails, for example with no network, and the user opens Settings
- **THEN** the remove-ads row shows no price, and tapping it neither crashes nor starts a purchase
