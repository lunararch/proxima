# Project Plan: Go-Linux Distribution

This document outlines a concrete, phased plan for developing a custom Linux distribution engineered to enable the addition and management of system features primarily through programs and modules written in Go.

## **Table of Contents**
1. [Phase 0: Project Setup & Governance](#phase-0-project-setup--governance-week-0)
2. [Phase 1: Foundation & Core Build System](#phase-1-foundation--core-build-system-weeks-1-4)
3. [Phase 2: Go Integration & Custom Init System](#phase-2-go-integration--custom-init-system-weeks-5-8)
4. [Phase 3: Package Management & Build Tooling](#phase-3-package-management--build-tooling-weeks-9-12)
5. [Phase 4: API, Security & Documentation](#phase-4-api-security--documentation-weeks-13-16)
6. [Phase 5: Finalization & Release](#phase-5-finalization--release-weeks-17-20)
7. [Phase 6: Stretch Goals (Post-Release)](#phase-6-stretch-goals-post-release)

---

### **Phase 0: Project Setup & Governance (Week 0)**

* **Key Tasks:**
    1.  **Repository Scaffolding:** Initialize Git repository, set up directory structure, and add initial README.
    2.  **Licensing & Policy:** Choose and add an open-source license (e.g., Apache 2.0), set up CLA policy, and document coding standards.
    3.  **Continuous Integration:** Set up CI pipeline (e.g., GitHub Actions) for build, lint, and QEMU boot smoke test (look for shell prompt or sentinel log line).
    4.  **Toolchain Pinning:** Lock toolchain versions (Go, GCC, Docker images) and document in a `TOOLCHAIN.md` file.
    5.  **Architectural Decision Records:** Create an `adr/` directory for tracking key design decisions.
    6.  **Initial Documentation:** Add a living `DEVELOPER_GUIDE.md` and `CONTRIBUTING.md`.

* **Milestone:** **Project is ready for collaborative development with clear policies and automated checks.**

---

### **Phase 1: Foundation & Core Build System (Weeks 1-4)**

The goal of this phase is to create a minimal, bootable Linux system. This provides the fundamental scaffolding upon which all Go-based features will be built.

* **Technology Stack:**
    * **Kernel:** Latest stable Linux Kernel (pinned version, config tracked in version control)
    * **Core Utilities:** [BusyBox](https://busybox.net/)
    * **Build Tools:** `make`, `gcc` (for cross-compilation), `Docker` (for a contained build environment)
    * **Virtualization:** `QEMU` for testing builds

* **Key Tasks:**
    1.  **Setup Build Environment:** Create a Docker container with all necessary cross-compilation toolchains for **x86_64** and **ARM**. This ensures a reproducible build process.
    2.  **Kernel Compilation:**
        * Download the latest stable Linux kernel source (pinned by SHA).
        * Create a minimal kernel configuration (`.config`) focused on virtualization drivers (like VirtIO) and support for target architectures. Store sanitized `.config` in version control.
        * Write a script to compile the kernel.
    3.  **Create Minimal Root Filesystem (rootfs):**
        * Compile BusyBox to provide essential Linux utilities (`sh`, `ls`, `mount`, `insmod`, etc.).
        * Structure a basic rootfs directory (`/bin`, `/sbin`, `/etc`, `/proc`, `/sys`, `/dev`).
        * Document storage layout, including `/var` persistence, tmpfs usage, and partitioning.
    4.  **Develop Initial Init Process:** Create a simple `/sbin/init` script (using BusyBox `ash`) that mounts pseudo-filesystems (`/proc`, `/sys`, `/dev`) and starts a shell.
    5.  **Automate the Build:** Create a master `Makefile` or `build.sh` script that automates the following steps:
        * Build the kernel.
        * Build the rootfs.
        * Combine the kernel and rootfs into a bootable image/ISO.
    6.  **Boot Test:** Use QEMU to boot the generated image and verify that you can get a shell prompt. Add automated boot regression test in CI.
    7.  **Supply Chain Integrity:** Generate SBOM (e.g., with `syft`) and checksums for all build artifacts.
    8.  **Acceptance Criteria:**
        * Image boots to shell in QEMU in under 10 seconds.
        * Image size under 50MB.
        * All build steps reproducible and pass in CI.

* **Milestone:** **A bootable, minimal Linux image that drops into a BusyBox shell.** 🚀

---

### **Phase 2: Go Integration & Custom Init System (Weeks 5-8)**

Now we introduce Go as a first-class citizen and replace the basic shell script `init` with a more robust Go application.

* **Technology Stack:**
    * **Language:** Go (latest stable version, pinned)
    * **Core Libraries:** Go Standard Library

* **Key Tasks:**
    1.  **Cross-Compile Go Runtime:** Integrate the Go toolchain into the build environment to cross-compile for the target architectures. Pin Go version and modules.
    2.  **Develop Go-based Init (`go-init`):**
        * Write a simple init daemon in Go. Its primary job is to be PID 1.
        * It should parse a simple configuration directory (e.g., `/etc/services/`) to find other services to launch.
        * It must handle reaping orphaned child processes (a key responsibility of PID 1).
        * Implement signal handling, supervised restarts, shutdown ordering, and panic logging.
        * Define a service manifest format (e.g., JSON/TOML): name, exec, env, user, restart policy, dependencies, readiness probe.
    3.  **Create First Go Service:** Write a simple Go-based logging daemon (`gologd`) that reads from the kernel message buffer (`/dev/kmsg`) and writes to a file in `/var/log/messages`.
    4.  **Integrate into Build:**
        * Modify the build script to compile `go-init` and `gologd` and place them in the rootfs.
        * Replace the BusyBox `/sbin/init` symlink with your new `go-init` binary.
        * Create the `/etc/services/gologd` configuration for `go-init` to discover and launch the logger.
    5.  **Test the Boot Process:** Boot the image in QEMU and verify that `go-init` starts successfully and launches the `gologd` daemon. Check for the existence and content of `/var/log/messages`.
    6.  **Testing:** Add unit tests for `go-init` and `gologd`. Add integration test to CI to check for log file creation.
    7.  **Security Hardening (Early):** Enable PIE, RELRO, and minimal syscall set for Go binaries. Document static vs dynamic linking decision.
    8.  **Acceptance Criteria:**
        * System boots with Go-based init and launches at least one Go daemon.
        * All tests pass in CI.
        * Panic and error logs are captured and accessible.

* **Milestone:** **The OS now boots using a Go-based init process which successfully launches another Go-based system daemon.** 💡

---

### **Phase 3: Package Management & Build Tooling (Weeks 9-12)**

This phase focuses on creating the infrastructure for adding new Go modules to the OS in a structured and automated way.

* **Key Tasks:**
    1.  **Define Module Structure:** Design a standard layout for a Go module repository. This should include Go source code, a simple manifest file (`module.json`) specifying the name, version, dependencies, and any static assets. Document module vetting policy (license, vulnerability scan).
    2.  **Create an Example Module Repository:** Set up a Git repository containing at least two simple example modules (e.g., an NTP client daemon and a basic SSH server using Go's `crypto/ssh` library).
    3.  **Develop the Build Integrator Tool (`go-builder`):**
        * Write a tool (in Go or as a shell script) that reads a master list of required modules (e.g., a `distro.json` file).
        * For each module, the tool will:
            * Fetch the source from its Git repository.
            * Statically compile the Go binary for the target architecture (`CGO_ENABLED=0`).
            * Install the binary and any assets into the correct location within the rootfs build directory.
            * Generate and verify checksums for all binaries.
            * Generate SBOM for included modules.
    4.  **Integrate `go-builder`:** Add a step in the master build script that runs `go-builder` after the core rootfs is created but before the final image is packaged.
    5.  **Deliverable: Go System Utilities:** Use this new system to build and integrate the **three required Go-based utilities**. For example:
        * **Service Manager:** A tool to interact with `go-init` to start/stop services.
        * **Network Configurator:** A utility to apply basic network settings from a config file.
        * **System Auditor:** A daemon that logs file changes in critical directories like `/etc`.
    6.  **Testing:** Add integration tests for module builder (mock repo, checksum verification). Add boot regression test for each new utility.
    7.  **Acceptance Criteria:**
        * Build system fetches, compiles, and integrates third-party Go modules automatically.
        * All utilities are discoverable and manageable by `go-init`.
        * All tests and SBOM generation pass in CI.

* **Milestone:** **The build system can automatically fetch, compile, and integrate third-party Go modules into the final OS image.** 📦

---

### **Phase 4: API, Security & Documentation (Weeks 13-16)**

With the core system in place, this phase focuses on making it secure, usable, and accessible to other developers.

* **Key Tasks:**
    1.  **Define a Configuration API:** Standardize how Go daemons are configured. A simple, effective approach is to have each daemon read its configuration from a corresponding file in `/etc/config/<daemon-name>.json`.
    2.  **Implement a Logging API:** Ensure all system daemons written in Go use a standardized logging library that outputs structured (e.g., JSON) logs to a central location managed by `gologd`. Define log schema, rotation policy, and severity mapping.
    3.  **Observability:** Instrument `go-init` and daemons with Prometheus metrics (expose on Unix socket or loopback). Add health endpoints for daemons.
    4.  **Security Hardening:**
        * Review all Go code for security best practices.
        * Ensure the kernel is configured with standard security features (e.g., AppArmor/SELinux stubs, stack protection).
        * Ensure all binaries are built as Position-Independent Executables (PIE).
        * Plan cgroup v2 integration for resource limits; optionally namespaces/seccomp profiles.
        * Add threat model overview (attack surface, supply chain, update channel).
    5.  **Write Developer Documentation:**
        * **`BUILD.md`:** Explain how to set up the build environment and compile the OS from scratch.
        * **`DEVELOPER_GUIDE.md`:** A comprehensive guide on how to write a new system service in Go. Explain the module structure, configuration API, logging API, and how to get it included in a build.
        * **Architecture Overview:** Document how `go-init` works and the overall philosophy of the OS.
        * **ADR Index:** Summarize key architectural decisions.
    6.  **Upgrade/Patch Strategy:** Define and document how to update modules or kernel post-install (future `gopkg` groundwork: signed manifests, version pinning).
    7.  **Acceptance Criteria:**
        * All APIs are documented and used by at least two daemons.
        * Security review completed and issues tracked.
        * All documentation deliverables present and up to date.

* **Milestone:** **A secure, well-documented base system with clear guidelines for extension and contribution.** ✍️

---

### **Phase 5: Finalization & Release (Weeks 17-20)**

This final phase is about polishing, testing, and packaging the deliverables.

* **Key Tasks:**
    1.  **ISO Generation:** Finalize the build scripts to produce clean, bootable ISO images for both **x86_64** and **ARM**.
    2.  **Multi-Architecture Testing:** Rigorously test both ISOs on QEMU and, if possible, on corresponding physical hardware. Document minimal hardware requirements and memory footprint goals.
    3.  **Finalize Example Repository:** Clean up the example Go modules repository and ensure its documentation is clear.
    4.  **Code Review and Cleanup:** Perform a final review of all custom Go code, ensuring it is idiomatic, commented, and includes unit tests.
    5.  **Package Deliverables:** Bundle the ISOs, all documentation, build scripts, SBOMs, and links to the example module repositories into a final package.
    6.  **Deterministic Build:** Provide deterministic build reproducibility target (bit-for-bit where feasible).
    7.  **Acceptance Criteria:**
        * All deliverables are complete, tested, and pass reproducibility checks.
        * All documentation and SBOMs are included in the release package.

* **Milestone:** **All project deliverables are complete, tested, and ready for distribution.** 🎉

---

### **Phase 6: Stretch Goals (Post-Release)**

These tasks can be tackled after the core deliverables are met.

* **Web Management Dashboard:**
    * Write a new Go daemon that runs a web server.
    * Create an API that allows the web server to communicate with `go-init` and other daemons (e.g., via RPC or a Unix socket) to manage services and display system status.
    * Build a lightweight frontend using Go's `html/template` package or a minimal JavaScript library.
* **Go-based Package Manager (`gopkg`):**
    * Develop a command-line tool that can run on the live OS.
    * This tool would fetch, compile, and install new modules from a curated repository, enabling system updates without a full rebuild and re-flash.
    * Implement signed manifests and version pinning for secure updates.
* **Container Support:**
    * Refine the build process to produce a minimal rootfs tarball in addition to the ISO.
    * Document the process of using this tarball as a base for a minimal Docker container, highlighting the benefits of statically linked Go binaries.
* **Additional Stretch Goals:**
    * Add support for cgroup v2 resource limits and seccomp profiles for all daemons.
    * Add support for system health dashboard and live metrics streaming.
    * Explore support for additional architectures (e.g., RISC-V).

---

## **Appendix**

* **Target Audience:** Embedded, education, and experimentation. Defaults favor minimalism and security.
* **Linking Policy:** Prefer static linking with musl for clarity and reproducibility; document exceptions.
* **Module Vetting:** All third-party Go modules must pass license and vulnerability scan before inclusion.
* **Naming, Branding, Governance:** To be decided in Phase 0 ADRs.
* **Timeline:** Aggressive; review and adjust as needed based on milestone acceptance criteria.
