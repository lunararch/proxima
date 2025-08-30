# ADR-0003: Use Go 1.25.0 for Development

## Status
Accepted

## Context
Need to select Go version balancing latest features, performance improvements, and ecosystem stability for the Go-Linux distribution.

## Decision
Use Go 1.25.0 as the locked version for development instead of the LTS 1.21.5.

## Rationale
- Access to latest language features and standard library improvements
- Better performance and toolchain optimizations
- Improved static linking capabilities
- Enhanced cross-compilation support
- Active development and community support

## Consequences
- **Positive**: Latest features, better performance, improved tooling
- **Negative**: Less long-term stability guarantees, potential ecosystem compatibility issues
- **Neutral**: More frequent version evaluation cycles, closer tracking of Go releases

## Review Policy
- Security updates: Apply immediately
- Monthly evaluation for patch releases
- Quarterly review for potential major version updates
