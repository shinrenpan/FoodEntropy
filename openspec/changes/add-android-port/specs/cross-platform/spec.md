## ADDED Requirements

### Requirement: iOS behaviour is unchanged by the port

The system SHALL keep every observable iOS behaviour identical to its pre-port state. Platform support SHALL NOT be a justification for changing what an iOS user sees or experiences.

#### Scenario: A platform branch is added to a shared file

- **WHEN** a file gains a branch so that the other platform can compile
- **THEN** the iOS build is run and its behaviour compared against the pre-port behaviour before the work is considered done

#### Scenario: The other platform would be easier to serve by changing iOS

- **WHEN** an implementation is simpler if an iOS behaviour changes
- **THEN** the iOS behaviour is kept and the other platform absorbs the complexity, because parity between platforms is not a goal that outranks iOS stability

### Requirement: Platform differences are expressed as compile-time branches, not abstractions

The system SHALL express every platform difference as a conditional compilation branch in the file that owns the behaviour, and SHALL NOT introduce protocols, wrappers, or indirection layers whose sole purpose is to hide a platform difference.

#### Scenario: One platform lacks an API the other has

- **WHEN** a framework exists on one platform only
- **THEN** the call site carries a branch: the original API on the platform that has it, an equivalent implementation on the platform that does not

#### Scenario: A difference spans an entire file

- **WHEN** a whole file is meaningful on one platform only
- **THEN** the entire file is excluded from the other platform rather than being partially rewritten, so the layering boundary stays where it was

#### Scenario: An abstraction is proposed to unify two implementations

- **WHEN** a protocol is proposed so both platforms can share a call site
- **THEN** it is rejected unless the call site count justifies it, because indirection converts a visible difference into a hidden one and changes the shape of the platform that already worked

### Requirement: The domain boundary is what makes the port possible and stays intact

The system SHALL keep the conversion to domain models as the single boundary between persistence and everything above it, on every platform. View models, states, and views SHALL remain unaware of which platform's storage implementation produced their data.

#### Scenario: A second storage implementation is introduced

- **WHEN** a platform requires a different storage technology
- **THEN** it exposes the same method names and returns the same domain types, so no view model changes

#### Scenario: A platform-specific type is tempting to leak upward

- **WHEN** a storage implementation holds a type that would be convenient to pass upward
- **THEN** it is converted at the boundary instead, because a leak here would force every consumer to branch on platform

### Requirement: A capability absent on one platform is removed there, not degraded everywhere

The system SHALL exclude a feature entirely on a platform that cannot support it, and SHALL NOT weaken or reshape that feature on the platform where it works in order to make the two platforms match.

#### Scenario: A platform has no equivalent for a service

- **WHEN** a feature depends on a service with no counterpart on the other platform
- **THEN** the feature ships on the platform that supports it and is excluded from the other, with the exclusion recorded as a deliberate scope decision

#### Scenario: The absent feature has visible entry points

- **WHEN** a feature is excluded from a platform
- **THEN** its entry points are excluded on that platform too, so no control is presented that cannot function

### Requirement: Runtime-only platform defects are prevented by rule, not by inspection

The system SHALL apply the known runtime rules for the Android branch uniformly rather than selectively, because the defects they prevent produce no compile-time error.

#### Scenario: A controller holds a view model on the non-iOS platform

- **WHEN** the controller layer constructs a view model for the non-iOS platform
- **THEN** it holds it in a way the UI framework tracks, otherwise state changes render nothing and no error is reported

#### Scenario: A view starts asynchronous work on appearance

- **WHEN** a view triggers work as it appears
- **THEN** the non-iOS branch uses an unstructured task, because navigation transitions can cancel structured work mid-flight and the cancellation surfaces as a spurious failure

#### Scenario: A closure captures the view model

- **WHEN** a closure on the non-iOS branch captures the view model
- **THEN** it captures it strongly, because that platform's memory model collects weak references while the object is still in use

### Requirement: The two unproven assumptions are validated before the bulk of the work

The system SHALL verify, in isolation and before broad porting begins, that the existing layering transpiles without restructuring and that the advertising SDK can be bridged. Each verification SHALL be a gate whose failure stops the work rather than a checkpoint that is noted and passed.

#### Scenario: The layering assumption is tested

- **WHEN** the port begins
- **THEN** a single screen backed by fixture data is brought up on both platforms first, touching neither storage nor advertising, so that a failure is attributable to the layering alone

#### Scenario: The bridging assumption is tested

- **WHEN** the layering gate passes
- **THEN** the advertising bridge is proven next, before storage and remaining screens, because it is the only part of the port with no established path

#### Scenario: A gate fails

- **WHEN** a gate does not pass
- **THEN** the port stops and is re-evaluated, and the toolchain binding is removed to return the project to its single-platform state
