APP_NAME = Dictate
SCHEME = Dictate
BUILD_DIR = .build/release-app
DERIVED_DATA = .build/derived
DMG_NAME = Dictate-1.0.0.dmg

.PHONY: build app dmg sign notarize clean

# Build release binary via xcodebuild (needed for SwiftUI macro support in dependencies)
build:
	xcodebuild build \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(DERIVED_DATA) \
		ONLY_ACTIVE_ARCH=NO

# Create .app bundle from release binary
app: build
	$(eval PRODUCTS_DIR := $(shell find $(DERIVED_DATA)/Build/Products/Release* -maxdepth 0 -type d 2>/dev/null | head -1))
	@mkdir -p "$(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS"
	@mkdir -p "$(BUILD_DIR)/$(APP_NAME).app/Contents/Resources"
	@cp "$(PRODUCTS_DIR)/$(APP_NAME)" "$(BUILD_DIR)/$(APP_NAME).app/Contents/MacOS/$(APP_NAME)"
	@cp Sources/Dictate/Info.plist "$(BUILD_DIR)/$(APP_NAME).app/Contents/Info.plist"
	@# Copy processed resources if the bundle exists
	@if [ -d "$(PRODUCTS_DIR)/Dictate_Dictate.bundle" ]; then \
		cp -R "$(PRODUCTS_DIR)/Dictate_Dictate.bundle/Contents/Resources/"* \
			"$(BUILD_DIR)/$(APP_NAME).app/Contents/Resources/" 2>/dev/null || true; \
	fi
	@echo "✅ Built $(BUILD_DIR)/$(APP_NAME).app"

# Create DMG with Applications symlink for drag-to-install
dmg: app
	@mkdir -p "$(BUILD_DIR)/dmg-staging"
	@cp -R "$(BUILD_DIR)/$(APP_NAME).app" "$(BUILD_DIR)/dmg-staging/"
	@ln -sf /Applications "$(BUILD_DIR)/dmg-staging/Applications"
	@hdiutil create -volname "$(APP_NAME)" \
		-srcfolder "$(BUILD_DIR)/dmg-staging" \
		-ov -format UDZO \
		"$(BUILD_DIR)/$(DMG_NAME)"
	@rm -rf "$(BUILD_DIR)/dmg-staging"
	@echo "✅ DMG created: $(BUILD_DIR)/$(DMG_NAME)"

# Code-sign the app (replace YOUR_NAME and TEAM_ID with your Developer ID)
sign: app
	codesign --force --deep --options runtime \
		--sign "Developer ID Application: YOUR_NAME (TEAM_ID)" \
		"$(BUILD_DIR)/$(APP_NAME).app"
	@echo "✅ App signed"

# Notarize the DMG with Apple (requires stored credentials)
# First run: xcrun notarytool store-credentials "notary-profile" --apple-id ... --team-id ... --password ...
notarize: sign dmg
	xcrun notarytool submit "$(BUILD_DIR)/$(DMG_NAME)" \
		--keychain-profile "notary-profile" \
		--wait
	xcrun stapler staple "$(BUILD_DIR)/$(DMG_NAME)"
	@echo "✅ DMG notarized and stapled"

# Remove build artifacts
clean:
	rm -rf "$(BUILD_DIR)" "$(DERIVED_DATA)"
	swift package clean
