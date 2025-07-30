#!/bin/bash

# FitGlide App Distribution Script
# This script handles app distribution via command line if Xcode Organizer fails

echo "🚀 Starting FitGlide App Distribution..."

# Configuration
TEAM_ID="L8UL9LXSNQ"
BUNDLE_ID_MAIN="com.TrailBlazeWellness.Fitglide-ios"
BUNDLE_ID_APPCLIP="com.TrailBlazeWellness.Fitglide-ios.appclip"
PROJECT_NAME="Fitglide_ios.xcodeproj"
SCHEME_MAIN="Fitglide_ios"
SCHEME_APPCLIP="Fitglide_appclip"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Clean and Archive Main App
print_status "Step 1: Archiving main app..."
xcodebuild clean -project $PROJECT_NAME -scheme $SCHEME_MAIN
if [ $? -ne 0 ]; then
    print_error "Failed to clean main app"
    exit 1
fi

xcodebuild archive -project $PROJECT_NAME -scheme $SCHEME_MAIN -archivePath "Fitglide_ios_main.xcarchive" -destination "generic/platform=iOS"
if [ $? -ne 0 ]; then
    print_error "Failed to archive main app"
    exit 1
fi

print_status "✅ Main app archived successfully"

# Step 2: Archive App Clip
print_status "Step 2: Archiving App Clip..."
xcodebuild clean -project $PROJECT_NAME -scheme $SCHEME_APPCLIP
if [ $? -ne 0 ]; then
    print_error "Failed to clean App Clip"
    exit 1
fi

xcodebuild archive -project $PROJECT_NAME -scheme $SCHEME_APPCLIP -archivePath "Fitglide_appclip.xcarchive" -destination "generic/platform=iOS"
if [ $? -ne 0 ]; then
    print_error "Failed to archive App Clip"
    exit 1
fi

print_status "✅ App Clip archived successfully"

# Step 3: Export Main App
print_status "Step 3: Exporting main app to App Store Connect..."
xcodebuild -exportArchive -archivePath "Fitglide_ios_main.xcarchive" -exportPath "Fitglide_ios_export" -exportOptionsPlist exportOptions.plist
if [ $? -ne 0 ]; then
    print_error "Failed to export main app"
    exit 1
fi

print_status "✅ Main app exported successfully"

# Step 4: Export App Clip
print_status "Step 4: Exporting App Clip to App Store Connect..."
xcodebuild -exportArchive -archivePath "Fitglide_appclip.xcarchive" -exportPath "Fitglide_appclip_export" -exportOptionsPlist exportOptions.plist
if [ $? -ne 0 ]; then
    print_error "Failed to export App Clip"
    exit 1
fi

print_status "✅ App Clip exported successfully"

# Step 5: Upload to App Store Connect
print_status "Step 5: Uploading to App Store Connect..."

# Upload main app
xcrun altool --upload-app --type ios --file "Fitglide_ios_export/Fitglide_ios.ipa" --username "your-apple-id@email.com" --password "@env:APP_SPECIFIC_PASSWORD"
if [ $? -ne 0 ]; then
    print_warning "Failed to upload main app via altool, trying xcrun notarytool..."
    
    # Alternative: Use notarytool for newer Xcode versions
    xcrun notarytool submit "Fitglide_ios_export/Fitglide_ios.ipa" --apple-id "your-apple-id@email.com" --password "@env:APP_SPECIFIC_PASSWORD" --team-id $TEAM_ID
fi

# Upload App Clip
xcrun altool --upload-app --type ios --file "Fitglide_appclip_export/Fitglide_appclip.ipa" --username "your-apple-id@email.com" --password "@env:APP_SPECIFIC_PASSWORD"
if [ $? -ne 0 ]; then
    print_warning "Failed to upload App Clip via altool, trying xcrun notarytool..."
    
    xcrun notarytool submit "Fitglide_appclip_export/Fitglide_appclip.ipa" --apple-id "your-apple-id@email.com" --password "@env:APP_SPECIFIC_PASSWORD" --team-id $TEAM_ID
fi

print_status "🎉 Distribution completed!"
print_status "Check App Store Connect for upload status"
print_status "Files exported to:"
echo "  - Fitglide_ios_export/"
echo "  - Fitglide_appclip_export/" 