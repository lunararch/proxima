# Contributing to Proxima

Thank you for your interest in contributing to Proxima, a Go-based Linux distribution! This document outlines the guidelines and processes for contributing to the project.

## Project Status

Proxima is currently in **Phase 0** (Project Setup & Governance) and is primarily developed by Tim Hofman. While the project is designed to eventually support collaborative development, we're establishing the foundational infrastructure first.

## How to Contribute

### Reporting Issues

- Use GitHub Issues to report bugs, request features, or ask questions
- Search existing issues before creating a new one
- Provide clear, detailed descriptions with steps to reproduce
- Include relevant system information (architecture, QEMU version, etc.)

### Code Contributions

#### Before Contributing

1. Review the [project plan](plan.md) to understand the current phase and priorities
2. Check the [Architectural Decision Records (ADRs)](adr/) for design decisions
3. Read the [Developer Guide](DEVELOPER_GUIDE.md) for technical details
4. Ensure your contribution aligns with the current phase objectives

#### Coding Standards

- **Language**: Go code must follow standard Go formatting (`gofmt`, `golint`)
- **Licensing**: All contributions are under Apache License 2.0
- **Static Linking**: Prefer static linking (see [ADR-0002](adr/0002-static-linking-policy.md))
- **Security**: All binaries must be built with PIE and RELRO enabled
- **Testing**: Include unit tests for Go code, integration tests for system components

#### Pull Request Process

1. Fork the repository and create a feature branch
2. Make your changes following the coding standards
3. Add or update tests as appropriate
4. Ensure all tests pass in CI (GitHub Actions)
5. Update documentation if needed
6. Submit a pull request with:
   - Clear description of changes
   - Reference to related issues
   - Test coverage information
   - Screenshots/logs for system-level changes

#### Commit Guidelines

- Use conventional commit format: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Keep commits atomic and well-documented
- Sign commits if possible

### Development Environment

- See [TOOLCHAIN.md](TOOLCHAIN.md) for pinned tool versions
- Use Docker for reproducible builds
- Test in QEMU before submitting
- Follow the build process in [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)

## Contributor License Agreement (CLA)

By contributing to Proxima, you agree that:

1. Your contributions are your original work or you have permission to contribute them
2. You grant the project maintainers a perpetual, worldwide, royalty-free license to use, modify, and distribute your contributions
3. Your contributions are provided under the Apache License 2.0
4. You have the right to make the contributions

## Code of Conduct

We expect all contributors to:

- Be respectful and professional in all interactions
- Focus on constructive feedback and collaboration
- Respect different viewpoints and experiences
- Prioritize the project's technical goals and user needs

## Getting Help

- Review existing documentation in the repository
- Check the [ADRs](adr/) for architectural context
- Open an issue for questions about contributing
- Tag @timhofman for urgent matters

## Recognition

Contributors will be acknowledged in:
- Git commit history
- Release notes for significant contributions
- Documentation credits where appropriate

## Future Governance

As the project grows beyond Phase 0, we will establish:
- Formal maintainer roles
- Enhanced review processes
- Community governance structures
- Expanded contributor guidelines

---

*This document will evolve as the project progresses through its development phases.*
