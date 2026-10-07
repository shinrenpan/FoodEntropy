## ADDED Requirements

### Requirement: The banner takes its width from the layout, not from the ad SDK

The system SHALL size the bridged ad banner from the width its container proposes and a fixed banner height, and SHALL NOT let the ad SDK's self-reported intrinsic size decide the banner's layout width. The SDK's banner view reports a size that grows with the width it was last laid out at and does not shrink back, so without this, a banner laid out at full width keeps that width when the space later narrows.

#### Scenario: Moving from one column to two keeps the ad inside its column

- **WHEN** the home screen is showing an ad in a single full-width column and the layout changes to two columns while the app is running
- **THEN** the ad stays within the home screen's column and does not overlap the settings column or extend past the screen edge

##### Example: Measured overflow without the fix

| Layout container | Without fix | With fix | Notes |
| ---------------- | ----------- | -------- | ----- |
| Two fixed-width columns | ad stays 637 pt wide, overlaps neighbour by 123 pt | contained | GoogleMobileAds 13.7.0 and 13.11.0 |
| Container that sizes columns from ideal sizes | home column stays 669 pt, covered by 236 pt | 0 overlap | GoogleMobileAds 13.7.0 |

Measured in the iPhone Duo simulator (Xcode 27.1 RC, iOS 27.1) on 2026-10-07 by reading frames at runtime, starting cold in inner-display portrait and rotating to landscape. The second row was measured with a container that sizes columns from their ideal sizes, which this app does not use; it is kept as contrasting evidence that the overflow does not depend on the container, and is not asserted by tests.

#### Scenario: Starting directly in two columns

- **WHEN** the app launches straight into the two-column layout
- **THEN** the ad is sized to the home screen's column from the start
