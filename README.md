# TreeTop Canopy Cover Setup

This repository contains a basic SwiftUI project. To use the `imageseg_canopy_model.mlpackage` for predicting canopy cover, follow these steps:

1. **Add the ML Package**
   - Locate the `imageseg_canopy_model.mlpackage` on your Mac.
   - Drag the package into the Xcode project navigator (recommend dropping it inside the `TreeTop` group).
   - In the dialog, be sure to check **Copy items if needed** and add it to the `TreeTop` target.
   - Xcode will compile the package into a `.mlmodelc` bundle that can be loaded at runtime.

2. **Use the Model in Code**
   - A helper type named `CanopyCoverAnalyzer` is included in `TreeTop/CanopyCoverAnalyzer.swift`.
   - Call `canopyCoverPercentage(for:)` with a `UIImage` to obtain the canopy cover percentage.

3. **Example**
   ```swift
   if let analyzer = CanopyCoverAnalyzer() {
       let percentage = try await analyzer.canopyCoverPercentage(for: image)
       print("Canopy cover: \(percentage)%")
   }
   ```

The helper uses Vision and Core ML to perform image segmentation and computes the ratio of canopy pixels to the total number of pixels.
