import Foundation
import UIKit

struct SummaryResult {
    let diagonalAverages: [String: Double]
    let overallAverage: Double
}

class SummaryGenerator {
    static func createSummary(forProjectAt url: URL) -> SummaryResult {
        var diagAverages: [String: Double] = [:]
        var allValues: [Double] = []

        for i in 1...2 {
            let diagName = "Diagonal \(i)"
            let photosURL = url
                .appendingPathComponent(diagName)
                .appendingPathComponent("View Contents")
                .appendingPathComponent("Photos")
            let masksURL = url
                .appendingPathComponent(diagName)
                .appendingPathComponent("View Contents")
                .appendingPathComponent("Masks")
            var values: [Double] = []
            if let files = try? FileManager.default.contentsOfDirectory(atPath: photosURL.path) {
                for file in files where file.lowercased().hasSuffix(".jpg") {
                    let photoURL = photosURL.appendingPathComponent(file)
                    if let image = UIImage(contentsOfFile: photoURL.path),
                       let result = MaskGenerator.shared.generateMask(for: image) {
                        let canopyPercent = (1.0 - result.skyMean) * 100.0
                        values.append(canopyPercent)
                        allValues.append(canopyPercent)
                        try? FileManager.default.createDirectory(at: masksURL, withIntermediateDirectories: true)
                        let maskURL = masksURL.appendingPathComponent(file)
                        if let data = result.mask.jpegData(compressionQuality: 0.9) {
                            try? data.write(to: maskURL)
                        }
                    }
                }
            }
            let avg = values.isEmpty ? 0.0 : values.reduce(0,+) / Double(values.count)
            diagAverages[diagName] = avg
        }
        let overall = allValues.isEmpty ? 0.0 : allValues.reduce(0,+) / Double(allValues.count)
        return SummaryResult(diagonalAverages: diagAverages, overallAverage: overall)
    }
}
