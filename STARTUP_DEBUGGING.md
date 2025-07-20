# TreeTop App Startup Debugging Guide

## Black Screen Issue - 30 Second Delay

### Root Causes Identified:
1. **Synchronous SwiftData ModelContainer initialization** - Fixed ✅
2. **Large existing project database** - Possible cause
3. **File system permissions/storage issues** - Device-specific
4. **CoreML model loading conflicts** - Less likely but possible

### Recent Fixes Applied:

#### 1. Asynchronous Database Initialization
- Moved ModelContainer creation to background thread
- UI now shows immediately while database loads
- Added proper error handling for initialization failures

#### 2. Improved Loading Screen
- Better visual feedback with animated loading indicator
- More informative loading messages
- Eliminates artificial 2-second delay

#### 3. Optimized ProjectManager
- Added preloading mechanism for better performance
- Background initialization to prevent UI blocking

### Debugging Steps for Users Still Experiencing Issues:

#### Step 1: Check Device Storage
- Ensure device has at least 1GB free space
- SwiftData requires space for database operations

#### Step 2: Reset App Data (if needed)
- Delete and reinstall the app
- This clears any corrupted SwiftData database

#### Step 3: Check iOS Version
- Ensure iOS 15.0+ for optimal SwiftData performance
- Earlier versions may have performance issues

#### Step 4: Device-Specific Testing
- Test on multiple device types
- Older devices (iPhone 8, iPad 6th gen) may load slower

### Performance Monitoring

Add these debug prints to track initialization times:

```swift
// In TreeTopApp.swift initializeModelContainer()
let startTime = Date()
print("🕐 Starting ModelContainer initialization...")

// After successful initialization:
let loadTime = Date().timeIntervalSince(startTime)
print("⏱️ ModelContainer loaded in \(String(format: "%.2f", loadTime))s")
```

### Expected Load Times:
- **Normal**: 0.5-2 seconds
- **First launch**: 1-3 seconds  
- **Large database**: 2-5 seconds
- **Problem**: >10 seconds indicates an issue

### Additional Optimizations to Consider:

1. **Lazy CoreML Loading**: Defer MaskGenerator initialization until needed
2. **Database Chunking**: Load projects in batches for very large databases
3. **Background App Refresh**: Preload during background refresh cycles

### Contact Developer If:
- Load time consistently exceeds 10 seconds
- App shows black screen with no loading indicator
- Initialization error messages appear
- Problem persists after reinstallation

## Monitoring in Future Releases

Consider adding analytics to track:
- Average initialization time per device type
- Frequency of initialization failures
- Database size correlation with load times
