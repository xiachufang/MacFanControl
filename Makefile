SCHEME      ?= MacFanControl
DESTINATION ?= platform=macOS,arch=arm64
DERIVED     ?= build
APP_NAME    ?= MacFanControl.app
RELEASE_APP := $(DERIVED)/Build/Products/Release/$(APP_NAME)
DEBUG_APP   := $(DERIVED)/Build/Products/Debug/$(APP_NAME)

.PHONY: help generate build release run run-debug test clean

help:
	@echo "Targets:"
	@echo "  make generate   # xcodegen generate"
	@echo "  make build      # Debug build"
	@echo "  make release    # Release build -> $(RELEASE_APP)"
	@echo "  make run        # Release build then open the app"
	@echo "  make run-debug  # Debug build then open the app"
	@echo "  make test       # swift test"
	@echo "  make clean      # remove $(DERIVED)/"

Signing.local.xcconfig:
	@echo "Signing.local.xcconfig is missing. Copy Signing.example.xcconfig and fill it in:"
	@echo "  cp Signing.example.xcconfig Signing.local.xcconfig"
	@exit 1

MacFanControl.xcodeproj: project.yml Signing.local.xcconfig
	xcodegen generate

generate: MacFanControl.xcodeproj

build: generate
	xcodebuild -scheme $(SCHEME) -configuration Debug \
		-destination '$(DESTINATION)' -derivedDataPath $(DERIVED) build

release: generate
	xcodebuild -scheme $(SCHEME) -configuration Release \
		-destination '$(DESTINATION)' -derivedDataPath $(DERIVED) build
	@echo "Built: $(RELEASE_APP)"

run: release
	open "$(RELEASE_APP)"

run-debug: build
	open "$(DEBUG_APP)"

test:
	swift test

clean:
	rm -rf $(DERIVED)
