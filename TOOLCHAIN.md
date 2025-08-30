# TOOLCHAIN.md

## Locked Toolchain Versions

### Core Languages & Runtimes
- **Go**: 1.25.0 (latest stable)
- **GCC**: 11.4.0 (cross-compilation)
- **Glibc**: 2.35
- **musl**: 1.2.4 (preferred for static linking)

### Kernel & Core System
- **Linux Kernel**: 6.1.69 (LTS)
- **BusyBox**: 1.36.1

### Build Environment
- **Docker Base**: ubuntu:22.04
- **Make**: 4.3
- **QEMU**: 7.2.0

### Go Dependencies
- All Go modules pinned via `go.mod`
- Vulnerability scanning: `govulncheck` latest
- Linting: `golangci-lint` v1.55.2

### Security Tools
- **SBOM Generation**: `syft` v0.100.0
- **Checksum**: `sha256sum` (coreutils 8.32)


## Update Policy
- Security patches: Apply immediately
