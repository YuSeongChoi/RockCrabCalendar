PROJECT_DIR ?= RockCrabCalendar
PROJECT ?= RockCrabCalendar.xcodeproj
SCHEME ?= RockCrabCalendar
DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=latest
APP_UNIT_TESTS_DIR ?= $(PROJECT_DIR)/RockCrabCalendarUnitTests
RUN_IOS_TESTS ?= 0

XCODEBUILD = xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)'

.PHONY: help open build test-unit test-app test-ui test-all test-modules test-module-shared test-module-domain test-module-data list-schemes list-destinations

help:
	@echo "Targets:"
	@echo "  make open              # Open Xcode project"
	@echo "  make build             # Build app scheme"
	@echo "  make test-modules      # Run SPM module tests (Shared -> Domain -> Data)"
	@echo "  make test-app          # Run app unit tests only (CI or RUN_IOS_TESTS=1)"
	@echo "  make test-unit         # Alias of test-app"
	@echo "  make test-ui           # Run UI tests only (CI or RUN_IOS_TESTS=1)"
	@echo "  make test-all          # Run module tests + app unit + UI tests"
	@echo "  make list-schemes      # List schemes"
	@echo "  make list-destinations # Show available destinations"
	@echo ""
	@echo "Overrides:"
	@echo "  DESTINATION='platform=iOS Simulator,name=iPhone 17,OS=latest'"
	@echo "  RUN_IOS_TESTS=1        # Force iOS simulator tests locally"

open:
	cd $(PROJECT_DIR) && open $(PROJECT)

build:
	cd $(PROJECT_DIR) && $(XCODEBUILD) build

test-unit:
	@$(MAKE) test-app

test-app:
	@if [ "$$CI" = "true" ] || [ "$(RUN_IOS_TESTS)" = "1" ]; then \
		if find $(APP_UNIT_TESTS_DIR) -type f -name '*Tests.swift' -print -quit 2>/dev/null | grep -q .; then \
			cd $(PROJECT_DIR) && $(XCODEBUILD) -only-testing:RockCrabCalendarUnitTests test; \
		else \
			echo "No app-level unit tests found under $(APP_UNIT_TESTS_DIR). Skipping."; \
		fi; \
	else \
		echo "Skipping app unit tests locally. Use RUN_IOS_TESTS=1 to run simulator tests."; \
	fi

test-module-shared:
	cd $(PROJECT_DIR)/Modules/RockCrabShared && arch -arm64 swift test

test-module-domain:
	cd $(PROJECT_DIR)/Modules/RockCrabDomain && arch -arm64 swift test

test-module-data:
	cd $(PROJECT_DIR)/Modules/RockCrabData && arch -arm64 swift test

test-modules: test-module-shared test-module-domain test-module-data

test-ui:
	@if [ "$$CI" = "true" ] || [ "$(RUN_IOS_TESTS)" = "1" ]; then \
		cd $(PROJECT_DIR) && $(XCODEBUILD) -only-testing:RockCrabCalendarUITests test; \
	else \
		echo "Skipping UI tests locally. Use RUN_IOS_TESTS=1 to run simulator tests."; \
	fi

test-all:
	@$(MAKE) test-modules
	@$(MAKE) test-app
	@$(MAKE) test-ui

list-schemes:
	cd $(PROJECT_DIR) && xcodebuild -list -project $(PROJECT)

list-destinations:
	cd $(PROJECT_DIR) && xcodebuild -showdestinations -project $(PROJECT) -scheme $(SCHEME)
