import UIKit
import CoreLocation
import SwiftUI

/// Represents a single canopy capture with analysis results
struct CanopyCaptureSummary {
    let image: UIImage
    let date: Date
    let location: CLLocationCoordinate2D
    let canopyPercentage: Double
}

/// ViewModel for managing canopy capture summaries
class CaptureViewModel: ObservableObject {
    @Published var summaries: [CanopyCaptureSummary] = []

    func saveSummary(image: UIImage, canopyPercent: Double, location: CLLocationCoordinate2D) {
        let summary = CanopyCaptureSummary(
            image: image,
            date: Date(),
            location: location,
            canopyPercentage: canopyPercent
        )
        summaries.append(summary)
    }
}
