#!/bin/bash

echo "🎯 Adding App Clip files to Xcode project..."

# Check if files exist
echo "📁 Checking for App Clip files..."

if [ -f "Fitglide_ios/Fitglide_iosAppClip.swift" ]; then
    echo "✅ Fitglide_iosAppClip.swift found"
else
    echo "❌ Fitglide_iosAppClip.swift not found"
fi

if [ -f "Fitglide_ios/AppClipExperienceView.swift" ]; then
    echo "✅ AppClipExperienceView.swift found"
else
    echo "❌ AppClipExperienceView.swift not found"
fi

if [ -f "Fitglide_ios/Fitglide_iosAppClip.entitlements" ]; then
    echo "✅ Fitglide_iosAppClip.entitlements found"
else
    echo "❌ Fitglide_iosAppClip.entitlements not found"
fi

if [ -f "Fitglide_ios/Fitglide_iosAppClip-Info.plist" ]; then
    echo "✅ Fitglide_iosAppClip-Info.plist found"
else
    echo "❌ Fitglide_iosAppClip-Info.plist not found"
fi

echo ""
echo "🎯 MANUAL STEPS TO ADD TO XCODE:"
echo "1. Right-click on your project in Xcode"
echo "2. Select 'Add Files to [ProjectName]'"
echo "3. Navigate to Fitglide_ios folder"
echo "4. Select the 4 App Clip files above"
echo "5. Make sure to check your App Clip target"
echo "6. Uncheck the main app target"
echo ""
echo "🏆 Your App Clip files are ready to be added!"
