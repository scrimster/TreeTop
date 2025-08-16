# TreeTop File Organization

## Overview
This document outlines how the TreeTop iOS app is organized. We've cleaned up the codebase to make it more maintainable and ready for App Store submission.

## File Structure

### Views/ (UI Components)
```
Views/
├── Core Views/
│   ├── ContentView.swift (24 lines)
│   ├── MainMenuView.swift (161 lines)
│   └── NewProjectView.swift (134 lines)
├── Project Views/
│   ├── ExistingProjectView.swift (414 lines) - Project list
│   ├── ProjectSearchBar.swift (54 lines) - Search functionality
│   ├── ProjectCard.swift (336 lines) - Individual project display
│   ├── FolderContentsView.swift (1,075 lines) - Main project view
│   ├── ProjectDataCard.swift (161 lines) - Project information
│   ├── DiagonalFolderView.swift (81 lines) - Diagonal controls
│   ├── ImageGalleryView.swift (94 lines) - Image gallery
│   └── AnalysisControlsView.swift (166 lines) - Analysis controls
├── Camera Views/
│   ├── LiveCameraView.swift (364 lines)
│   └── CenterReferenceCameraView.swift (262 lines)
├── Background Views/
│   ├── AnimatedForestBackground.swift (168 lines)
│   └── SimpleForestBackground.swift (42 lines)
└── Utility Views/
    ├── LoadingView.swift (98 lines)
    ├── ShareSheet.swift (17 lines)
    └── [Other utility views...]
```

### Managers/ (Business Logic)
```
Managers/
├── Core Managers/
│   ├── ProjectManager.swift (317 lines) - Project data management
│   ├── CameraManager.swift (303 lines) - Camera functionality
│   └── LocationManager.swift (148 lines) - GPS and location
├── Analysis Managers/
│   ├── MaskGenerator.swift (189 lines) - Image segmentation
│   ├── SummaryGenerator.swift (206 lines) - Analysis processing
│   └── PDFExportManager.swift (327 lines) - PDF report generation
├── Utility Managers/
│   ├── CanopyCaptureSummary.swift (27 lines) - Analysis results
│   ├── ImageCache.swift (36 lines) - Image caching
│   ├── Notifications.swift (9 lines) - App notifications
│   ├── ProjectStatisticsManager.swift (87 lines) - Statistics
│   ├── SafetyExtensions.swift (37 lines) - Safety utilities
│   └── UIImageExtensions.swift (181 lines) - Image utilities
```

### Models/ (Data Models)
```
Models/
├── ProjectModel.swift (163 lines) - Project data structure
├── LocationModel.swift (50 lines) - Location data
├── ProjectPinModel.swift (16 lines) - Map pins
└── CanopyModel - MinReproductionPackage/
    └── [Core ML model files]
```

## Future Work

### Potential Improvements
- Consider breaking down `MapView.swift` if it gets bigger
- Extract common UI patterns into reusable components
- Add unit tests for new components
- Optimize performance based on user feedback