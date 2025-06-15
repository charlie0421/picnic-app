#!/bin/bash

# Android Build Script for CI/CD
# This script bypasses Flutter's APK detection issues

set -e  # Exit on any error

echo "🚀 Starting Android build process..."

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "📦 Getting Flutter dependencies..."
flutter pub get

echo "🧹 Cleaning previous builds..."
flutter clean

echo "🔧 Building Flutter assets..."
flutter build apk --release --target-platform android-arm,android-arm64,android-x64 || true

# Even if Flutter build fails, we can still use Gradle directly
echo "⚡ Building with Gradle directly..."
cd android
./gradlew clean
./gradlew assembleRelease

echo "📱 Building AAB (App Bundle)..."
./gradlew bundleRelease

cd ..

# Copy files to easier locations with timestamps
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
APK_SOURCE="android/app/build/outputs/apk/release/app-release.apk"
AAB_SOURCE="android/app/build/outputs/bundle/release/app-release.aab"

if [ -f "$APK_SOURCE" ]; then
    cp "$APK_SOURCE" "picnic-app-${TIMESTAMP}.apk"
    cp "$APK_SOURCE" "picnic-app-release.apk"
    echo "✅ APK created: picnic-app-release.apk"
    ls -lh "picnic-app-release.apk"
else
    echo "❌ APK not found at $APK_SOURCE"
    exit 1
fi

if [ -f "$AAB_SOURCE" ]; then
    cp "$AAB_SOURCE" "picnic-app-${TIMESTAMP}.aab"
    cp "$AAB_SOURCE" "picnic-app-release.aab"
    echo "✅ AAB created: picnic-app-release.aab"
    ls -lh "picnic-app-release.aab"
else
    echo "❌ AAB not found at $AAB_SOURCE"
    exit 1
fi

echo "🎉 Build completed successfully!"
echo "📋 Build artifacts:"
echo "   - APK: picnic-app-release.apk"
echo "   - AAB: picnic-app-release.aab"
echo "   - With timestamp: picnic-app-${TIMESTAMP}.{apk,aab}" 