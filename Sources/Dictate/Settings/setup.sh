#!/bin/bash

# Dictate App - Quick Setup Script
# This script helps you get the Dictate app running in Xcode

set -e

echo "🎙️  Dictate App - Quick Setup"
echo "=============================="
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the Mac App Store."
    exit 1
fi

echo "✅ Xcode detected: $(xcodebuild -version | head -n1)"
echo ""

# Check for Swift
SWIFT_VERSION=$(swift --version | head -n1)
echo "✅ Swift detected: $SWIFT_VERSION"
echo ""

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
echo "✅ macOS version: $MACOS_VERSION"
echo ""

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
    echo "⚠️  Warning: This app is optimized for Apple Silicon (arm64). You're running on $ARCH."
    echo "   The app may still work, but performance will be limited."
fi
echo ""

# Resolve dependencies
echo "📦 Resolving Swift package dependencies..."
swift package resolve

echo ""
echo "✅ Dependencies resolved!"
echo ""

# Open in Xcode
echo "🚀 Opening project in Xcode..."
open Package.swift

echo ""
echo "=============================="
echo "Next steps:"
echo "1. Wait for Xcode to finish indexing (watch the progress bar)"
echo "2. Press ⌘R to build and run"
echo "3. Grant microphone access when prompted"
echo "4. The app will appear in your menu bar (waveform icon)"
echo "5. Press ⌥R to start recording!"
echo ""
echo "📚 For detailed setup instructions, see XCODE_SETUP.md"
echo "=============================="
