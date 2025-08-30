# ADR-0002: Prefer Static Linking with musl

## Status
Accepted

## Context
We need to decide on linking strategy for Go binaries and system dependencies to balance size, security, and reproducibility.

## Decision
- All Go binaries will be statically linked (`CGO_ENABLED=0`)
- System utilities will use musl libc for static linking
- Dynamic linking only for kernel modules and drivers

## Consequences
- **Positive**: Simplified deployment, no dependency conflicts, smaller attack surface
- **Negative**: Larger binary sizes, more complex security updates
- **Neutral**: Clear boundary between static userspace and dynamic kernel space