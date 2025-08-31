# Developer Guide

This guide provides comprehensive information for developers working on Proxima, a Go-based Linux distribution. Whether you're contributing to the core system or developing Go modules for the platform, this document will help you understand the architecture, build process, and development workflows.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Development Environment Setup](#development-environment-setup)
3. [Build System](#build-system)
4. [Go Module Development](#go-module-development)
5. [Testing Strategy](#testing-strategy)
6. [Debugging](#debugging)
7. [Security Considerations](#security-considerations)
8. [Release Process](#release-process)

## Architecture Overview

Proxima is designed as a minimal Linux distribution where system services are primarily implemented in Go. The key architectural components are:

### Core Components

- **Linux Kernel**: Minimal configuration focused on virtualization and target architectures
- **BusyBox**: Essential POSIX utilities and shell
- **go-init**: Custom PID 1 init system written in Go
- **Go Services**: System daemons and utilities written in Go

### Design Principles

- **Static Linking**: All Go binaries are statically linked for simplicity and reproducibility
- **Minimal Dependencies**: Reduce attack surface and complexity
- **Structured Configuration**: JSON-based configuration for all services
- **Centralized Logging**: Structured logging through `gologd`
- **Modular Architecture**: Services are independent and discoverable

See [ADR directory](adr/) for detailed architectural decisions.

## Development Environment Setup

### Prerequisites

Ensure you have the required tools installed (see [TOOLCHAIN.md](TOOLCHAIN.md) for pinned versions):

- Docker
- Make
- Git
- QEMU (for testing)

### Environment Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd proxima
   ```

2. **Verify toolchain**:
   ```bash
   make verify-toolchain
   ```

3. **Set up Docker build environment**:
   ```bash
   make build-env
   ```

### Directory Structure

```
proxima/
├── build/           # Build artifacts and intermediate files
├── rootfs/          # Root filesystem template
├── kernel/          # Kernel configuration and patches
├── services/        # Core Go services source code
├── modules/         # External Go modules integration
├── scripts/         # Build and utility scripts
├── tests/           # Test suites
└── docs/            # Additional documentation
```

## Build System

### Overview

The build system is designed for reproducibility and supports cross-compilation for multiple architectures.

### Build Targets

- `make all` - Build complete system for all architectures
- `make kernel` - Build kernel only
- `make rootfs` - Build root filesystem
- `make iso` - Generate bootable ISO
- `make test` - Run all tests
- `make clean` - Clean build artifacts

### Cross-Compilation

Proxima supports multiple architectures:
- x86_64
- ARM (armv7l)
- ARM64 (aarch64)

Set target architecture:
```bash
make ARCH=arm64 iso
```

### Docker Build Environment

All builds run in a containerized environment to ensure reproducibility:

```bash
# Enter build environment
make shell

# Build inside container
make ARCH=x86_64 all
```

## Go Module Development

### Service Architecture

Go services in Proxima follow a standard pattern:

```go
package main

import (
    "context"
    "encoding/json"
    "log"
    "os"
    "os/signal"
    "syscall"
)

type Config struct {
    // Service-specific configuration
}

func main() {
    // Load configuration from /etc/config/<service-name>.json
    config := loadConfig()
    
    // Initialize service
    service := NewService(config)
    
    // Setup signal handling
    ctx, cancel := context.WithCancel(context.Background())
    sigChan := make(chan os.Signal, 1)
    signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
    
    go func() {
        <-sigChan
        cancel()
    }()
    
    // Run service
    if err := service.Run(ctx); err != nil {
        log.Fatal(err)
    }
}
```

### Configuration API

All services read configuration from `/etc/config/<service-name>.json`:

```json
{
    "enabled": true,
    "log_level": "info",
    "bind_address": "127.0.0.1:8080",
    "service_specific_options": {
        "key": "value"
    }
}
```

### Logging API

Use structured logging that integrates with `gologd`:

```go
import "log/slog"

// Create structured logger
logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

// Log with context
logger.Info("Service started",
    "service", "example-service",
    "version", "1.0.0",
    "pid", os.Getpid(),
)
```

### Service Manifest

Each service requires a manifest file for `go-init` integration:

```json
{
    "name": "example-service",
    "exec": "/usr/bin/example-service",
    "env": {},
    "user": "root",
    "restart_policy": "always",
    "dependencies": ["network"],
    "readiness_probe": {
        "type": "http",
        "endpoint": "http://localhost:8080/health",
        "timeout": "5s"
    }
}
```

### Building Services

1. **Create service directory**: `services/<service-name>/`
2. **Implement service**: Follow the standard pattern above
3. **Add to build system**: Update `services/Makefile`
4. **Add manifest**: Place in `rootfs/etc/services/<service-name>.json`
5. **Add configuration**: Place template in `rootfs/etc/config/<service-name>.json`

### External Modules

For external Go modules, create a module descriptor:

```json
{
    "name": "external-module",
    "version": "v1.0.0",
    "repository": "https://github.com/example/module",
    "commit": "abc123...",
    "build_cmd": "go build -o bin/module ./cmd/module",
    "assets": [
        {"src": "bin/module", "dst": "/usr/bin/module"},
        {"src": "config.json", "dst": "/etc/config/module.json"}
    ],
    "service_manifest": "service.json"
}
```

## Testing Strategy

### Unit Tests

Write unit tests for all Go code:

```bash
# Run unit tests
make test-unit

# Run with coverage
make test-coverage
```

### Integration Tests

Test service interactions and system behavior:

```bash
# Run integration tests
make test-integration
```

### Boot Tests

Automated tests verify the system boots correctly:

```bash
# Test boot process
make test-boot

# Test specific architecture
make ARCH=arm64 test-boot
```

### QEMU Testing

Manual testing in QEMU:

```bash
# Boot ISO in QEMU
make qemu

# Boot with console access
make qemu-console

# Boot with network
make qemu-network
```

## Debugging

### Kernel Debugging

Enable kernel debugging in QEMU:

```bash
make qemu-debug
```

This enables:
- Kernel debug output
- GDB integration
- Extended console logging

### Service Debugging

Debug Go services:

1. **Enable debug logging**: Set `log_level: "debug"` in service config
2. **View logs**: Check `/var/log/services/<service-name>.log`
3. **Service status**: Use `service-manager status <service-name>`

### Build Debugging

Debug build issues:

```bash
# Verbose build output
make V=1 all

# Keep intermediate files
make DEBUG=1 all

# Enter build environment for manual inspection
make shell
```

## Security Considerations

### Binary Hardening

All Go binaries are built with security features:

- Position Independent Executables (PIE)
- Read-only relocations (RELRO)
- Stack protection
- Static linking (no dynamic dependencies)

### Privilege Management

- Services run with minimal required privileges
- Use dedicated users where possible
- Implement capability-based security

### Supply Chain Security

- All dependencies are pinned by version/commit
- SBOM generation for all builds
- Checksum verification for all artifacts

### Security Testing

```bash
# Run security scans
make security-scan

# Check for vulnerabilities
make vuln-check
```

## Release Process

### Version Management

Proxima uses semantic versioning (MAJOR.MINOR.PATCH):

- MAJOR: Incompatible API changes
- MINOR: Backward-compatible functionality additions
- PATCH: Backward-compatible bug fixes

### Release Checklist

1. **Update version**: Update version in relevant files
2. **Run full test suite**: `make test-all`
3. **Generate SBOMs**: `make sbom`
4. **Build release artifacts**: `make release`
5. **Security scan**: `make security-scan`
6. **Update documentation**: Update CHANGELOG.md
7. **Tag release**: Create Git tag
8. **Publish artifacts**: Upload to release page

### Continuous Integration

GitHub Actions automatically:
- Runs tests on all supported architectures
- Builds ISOs for pull requests
- Performs security scans
- Generates build artifacts

### Reproducible Builds

Builds are designed to be reproducible:
- Pinned toolchain versions
- Deterministic timestamps
- Consistent build environment

## Getting Help

- **Issues**: Open GitHub issues for bugs or questions
- **Documentation**: Check [ADRs](adr/) for architectural decisions
- **Community**: Join project discussions
- **Code Review**: Submit pull requests for feedback

---

*This guide evolves with the project. Please keep it updated as new features and processes are added.*
