.PHONY: build test lint checksums clean

DIST_DIR := dist
ISO_NAME := proxima.iso

build:
	@echo "Building kernel and rootfs ..."
	@mkdir -p $(DIST_DIR)

	@touch $(DIST_DIR)/$(ISO_NAME)

test:
	@echo "running tests ..."
	go test ./...

lint:
	@echo "Running linter ..."
	golangci-lint run

checksums:
	@echo "Generating checksums ..."
	cd $(DIST_DIR) && sha256sum * > checksums.sha256

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(DIST_DIR)