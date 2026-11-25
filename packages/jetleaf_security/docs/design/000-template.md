# NNN — Component name

## Design reference
The abstraction this component provides and the problem it solves; where possible, the underlying contract it implements.

## Problem
The production failure this abstraction exists to prevent. Write the failure, not the feature.

## Invariant
Numbered, imperative, testable statements. These are the non-negotiables.

## Extension seam
What users may replace, and the pod/interface/order that governs it. Every default MUST be overridable.

## Edge cases
The regressions, CVEs, and boundary conditions that motivated the design.

## Jetleaf mapping
Concrete Jetleaf types and primitives used, plus every deviation with rationale.

## Gating tests
Named tests that prove the invariant, including at least one adversarial case.