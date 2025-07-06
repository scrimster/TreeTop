import Foundation
import CoreLocation
import SwiftUI

class CaptureViewModel: ObservableObject {
    @Published var summaries: [CanopyCaptureSummary] = []

    func saveSummary(image: UIImage, canopyPercent: Double) {
        let currentDate = Date()

        // Format the time as a short string (e.g., "4:30 PM")
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timeString = timeFormatter.string(from: currentDate)

        let summary = CanopyCaptureSummary(
            image: image,
            date: currentDate,
            time: timeString,
            canopyPercentage: canopyPercent
        )
        summaries.append(summary)
    }
}
