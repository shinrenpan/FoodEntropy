## ADDED Requirements

### Requirement: The root is a single navigation controller hosting the home screen

The system SHALL use a `UINavigationController` as the window's root view controller, with the home screen as its root view controller, and SHALL NOT place a tab bar at the root. Every other in-app screen SHALL be reached by pushing onto that one stack. Navigation bar titles SHALL come from the String Catalog.

#### Scenario: Launch shows the home screen with no tab bar

- **WHEN** the app finishes launching
- **THEN** the home screen is shown as the root of a navigation stack, and no tab bar occupies the bottom of the screen

#### Scenario: Every screen shares one navigation stack

- **WHEN** the user opens settings from the home screen and then opens a food item from a deeplink
- **THEN** both screens resolve against the same navigation stack, and the deeplink returns to the home screen before pushing the item rather than stacking on top of settings

## REMOVED Requirements

### Requirement: The root is a two-tab controller with per-tab navigation stacks

**Reason**: A tab bar is for peer destinations the user switches between often. Settings is subordinate to the food list and is visited rarely, so it becomes a pushed screen reached from the home screen's navigation bar. Removing the tab bar also returns roughly one list row of vertical space at the bottom of the home screen, where the list is already clipped.

**Migration**: The window's root view controller becomes a single `UINavigationController` whose root is the home screen, as described by "The root is a single navigation controller hosting the home screen". Settings is pushed onto that stack instead of occupying a tab. The per-tab navigation stacks and the tab titles they carried no longer exist.

## MODIFIED Requirements

### Requirement: Debug-only environment switches are excluded from Release builds

The system SHALL confine every environment-variable escape hatch — including the screenshot mode that pre-grants the ad-removal entitlement and the mock-seeding switch — to `#if DEBUG` compilation blocks, so that no such code path exists in a Release build.

#### Scenario: A Release build ignores the screenshot-mode entitlement override

- **WHEN** a Release build is launched with the screenshot-mode environment variable set
- **THEN** the ad-removal entitlement is determined solely by StoreKit, and ads are shown to a user who has not purchased removal

#### Scenario: A Release build ignores mock seeding

- **WHEN** a Release build is launched with the mock-seeding environment variable set
- **THEN** no mock data is created and the app opens on the home screen
