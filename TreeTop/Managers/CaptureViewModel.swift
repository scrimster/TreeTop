import Foundation
import CoreLocation
import SwiftUI

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
