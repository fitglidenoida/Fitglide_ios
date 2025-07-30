# FitGlide Project Restoration Guide

## Current Status
✅ Main iOS app target - Working  
❌ Watch app target - Missing from project  
❌ App Clip target - Missing from project  
❌ Multiple @main conflicts - Fixed  
❌ Asset catalog issues - Need to resolve  

## Step-by-Step Restoration Process

### 1. Open Project in Xcode
```bash
open Fitglide_ios.xcodeproj
```

### 2. Add Watch App Target
1. In Xcode: **File → New → Target**
2. Choose: **watchOS → Watch App**
3. Product Name: `Fitglide_Watch_App Watch App`
4. Language: **Swift**
5. Interface: **SwiftUI**
6. **Uncheck**: "Include Notification Scene"
7. Click **Finish**

### 3. Add App Clip Target
1. In Xcode: **File → New → Target**
2. Choose: **iOS → App Clip**
3. Product Name: `Fitglide_appclip`
4. Language: **Swift**
5. Interface: **SwiftUI**
6. Click **Finish**

### 4. Replace Generated Files with Existing Files

#### Watch App Files to Replace:
- Replace `ContentView.swift` with existing version
- Add `WatchTheme.swift` (already exists)
- Add `HealthService.swift` (already exists)
- Add `WorkoutManager.swift` (already exists)
- Add `WorkoutPickerView.swift` (already exists)
- Add `LiveCheerManager.swift` (already exists)
- Add `LiveCheerSettingsView.swift` (already exists)

#### App Clip Files to Replace:
- Replace `ContentView.swift` with existing version
- Replace `Fitglide_appclipApp.swift` with existing version
- Replace `Info.plist` with existing version
- Replace `Fitglide_appclip.entitlements` with existing version

### 5. Fix Asset Catalog Issues
1. **App Clip Icons**: Copy all icon files from main app to App Clip asset catalog
2. **Watch App Icons**: Ensure Watch app has proper icon set

### 6. Build Configuration
1. **Main App**: Should build without issues
2. **Watch App**: Ensure all files are added to Watch app target
3. **App Clip**: Ensure all files are added to App Clip target

### 7. Test Each Target
1. Build main app target
2. Build Watch app target
3. Build App Clip target
4. Archive each target separately

## File Locations After Restoration

### Main App Files (✅ Working)
- `Fitglide_ios/` - Main app source files
- `Fitglide_ios.xcodeproj/project.pbxproj` - Project configuration

### Watch App Files (Need to add to target)
- `Fitglide_Watch_App Watch App/ContentView.swift`
- `Fitglide_Watch_App Watch App/WatchTheme.swift`
- `Fitglide_Watch_App Watch App/HealthService.swift`
- `Fitglide_Watch_App Watch App/WorkoutManager.swift`
- `Fitglide_Watch_App Watch App/WorkoutPickerView.swift`
- `Fitglide_Watch_App Watch App/LiveCheerManager.swift`
- `Fitglide_Watch_App Watch App/LiveCheerSettingsView.swift`

### App Clip Files (Need to add to target)
- `Fitglide_appclip/ContentView.swift`
- `Fitglide_appclip/Fitglide_appclipApp.swift`
- `Fitglide_appclip/Info.plist`
- `Fitglide_appclip/Fitglide_appclip.entitlements`

## Expected Outcome
After following these steps, you should have:
- ✅ Main iOS app building successfully
- ✅ Watch app building successfully with proper theme
- ✅ App Clip building successfully
- ✅ All targets ready for archiving and distribution

## Troubleshooting
- If targets don't appear, restart Xcode
- If files aren't found, use "Add Files to Project" manually
- If build errors persist, clean build folder and rebuild 