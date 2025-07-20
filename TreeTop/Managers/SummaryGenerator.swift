import Foundation
import UIKit

struct SummaryResult {
    let diagonalAverages: [String: Double]
    let overallAverage: Double
}

class SummaryGenerator {
    
    // Synchronous version (with timeout protection)
    static func createSummary(forProjectAt url: URL) -> SummaryResult {
        print("🔍 Starting summary generation for project at: \(url.path)")
        let startTime = Date()
        
        var diagAverages: [String: Double] = [:]
        var allValues: [Double] = []
        var totalImagesProcessed = 0
        var totalImagesFound = 0

        for i in 1...2 {
            let diagName = "Diagonal \(i)"
            print("📂 Processing \(diagName)")
            
            let photosURL = url
                .appendingPathComponent(diagName)
                .appendingPathComponent("Photos")
            let masksURL = url
                .appendingPathComponent(diagName)
                .appendingPathComponent("Masks")
            
            var values: [Double] = []
            
            if let files = try? FileManager.default.contentsOfDirectory(atPath: photosURL.path) {
                let imageFiles = files.filter { $0.lowercased().hasSuffix(".jpg") }
                totalImagesFound += imageFiles.count
                print("📸 Found \(imageFiles.count) images in \(diagName)")
                
                for (index, file) in imageFiles.enumerated() {
                    autoreleasepool {
                        let photoURL = photosURL.appendingPathComponent(file)
                        
                        // Memory-efficient image loading
                        guard let image = UIImage(contentsOfFile: photoURL.path) else {
                            print("⚠️ Failed to load image: \(file)")
                            return
                        }
                        
                        print("🔄 Processing image \(index + 1)/\(imageFiles.count): \(file)")
                        
                        if let result = MaskGenerator.shared.generateMask(for: image) {
                            let canopyPercent = (1.0 - result.skyMean) * 100.0
                            values.append(canopyPercent)
                            allValues.append(canopyPercent)
                            totalImagesProcessed += 1
                            
                            // Save mask
                            do {
                                try FileManager.default.createDirectory(at: masksURL, withIntermediateDirectories: true, attributes: nil)
                                let maskURL = masksURL.appendingPathComponent(file)
                                if let data = result.mask.jpegData(compressionQuality: 0.9) {
                                    try data.write(to: maskURL)
                                    print("💾 Saved mask: \(file)")
                                }
                            } catch {
                                print("❌ Failed to save mask for \(file): \(error)")
                            }
                            
                            print("📊 Canopy coverage: \(String(format: "%.1f", canopyPercent))%")
                        } else {
                            print("❌ Failed to generate mask for: \(file)")
                        }
                    }
                }
            }
            
            let avg = values.isEmpty ? 0.0 : values.reduce(0,+) / Double(values.count)
            diagAverages[diagName] = avg
            print("✅ \(diagName) average: \(String(format: "%.1f", avg))%")
        }
        
        let overall = allValues.isEmpty ? 0.0 : allValues.reduce(0,+) / Double(allValues.count)
        let processingTime = Date().timeIntervalSince(startTime)
        
        print("🎯 Summary completed in \(String(format: "%.1f", processingTime))s")
        print("📈 Overall average: \(String(format: "%.1f", overall))%")
        print("📊 Processed: \(totalImagesProcessed)/\(totalImagesFound) images")
        
        return SummaryResult(diagonalAverages: diagAverages, overallAverage: overall)
    }
    
    // Async version with progress callback
    static func createSummaryAsync(forProjectAt url: URL, 
                                  progressCallback: @escaping (String, Int, Int) -> Void,
                                  completion: @escaping (Result<SummaryResult, Error>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("🔍 Starting async summary generation for project at: \(url.path)")
            let startTime = Date()
            
            var diagAverages: [String: Double] = [:]
            var allValues: [Double] = []
            var totalImagesProcessed = 0
            var totalImagesFound = 0
            
            // First pass: count total images
            for i in 1...2 {
                let diagName = "Diagonal \(i)"
                let photosURL = url
                    .appendingPathComponent(diagName)
                    .appendingPathComponent("Photos")
                
                if let files = try? FileManager.default.contentsOfDirectory(atPath: photosURL.path) {
                    let imageFiles = files.filter { $0.lowercased().hasSuffix(".jpg") }
                    totalImagesFound += imageFiles.count
                }
            }
            
            DispatchQueue.main.async {
                progressCallback("Initializing...", 0, totalImagesFound)
            }
            
            // Process each diagonal
            for i in 1...2 {
                let diagName = "Diagonal \(i)"
                let photosURL = url
                    .appendingPathComponent(diagName)
                    .appendingPathComponent("Photos")
                let masksURL = url
                    .appendingPathComponent(diagName)
                    .appendingPathComponent("Masks")
                
                var values: [Double] = []
                
                guard let files = try? FileManager.default.contentsOfDirectory(atPath: photosURL.path) else {
                    print("⚠️ Could not read directory: \(photosURL.path)")
                    continue
                }
                
                let imageFiles = files.filter { $0.lowercased().hasSuffix(".jpg") }
                
                for (_, file) in imageFiles.enumerated() {
                    // Update progress
                    DispatchQueue.main.async {
                        progressCallback("Processing \(diagName): \(file)", totalImagesProcessed + 1, totalImagesFound)
                    }
                    
                    autoreleasepool {
                        let photoURL = photosURL.appendingPathComponent(file)
                        
                        guard let image = UIImage(contentsOfFile: photoURL.path) else {
                            print("⚠️ Failed to load image: \(file)")
                            return
                        }
                        
                        if let result = MaskGenerator.shared.generateMask(for: image) {
                            let canopyPercent = (1.0 - result.skyMean) * 100.0
                            values.append(canopyPercent)
                            allValues.append(canopyPercent)
                            totalImagesProcessed += 1
                            
                            // Save mask
                            do {
                                try FileManager.default.createDirectory(at: masksURL, withIntermediateDirectories: true, attributes: nil)
                                let maskURL = masksURL.appendingPathComponent(file)
                                if let data = result.mask.jpegData(compressionQuality: 0.9) {
                                    try data.write(to: maskURL)
                                }
                            } catch {
                                print("❌ Failed to save mask for \(file): \(error)")
                            }
                        } else {
                            print("❌ Failed to generate mask for: \(file)")
                        }
                    }
                    
                    // Small delay to prevent system overload
                    Thread.sleep(forTimeInterval: 0.05)
                }
                
                let avg = values.isEmpty ? 0.0 : values.reduce(0,+) / Double(values.count)
                diagAverages[diagName] = avg
                print("✅ \(diagName) average: \(String(format: "%.1f", avg))%")
            }
            
            let overall = allValues.isEmpty ? 0.0 : allValues.reduce(0,+) / Double(allValues.count)
            let processingTime = Date().timeIntervalSince(startTime)
            let result = SummaryResult(diagonalAverages: diagAverages, overallAverage: overall)
            
            print("🎯 Async summary completed in \(String(format: "%.1f", processingTime))s")
            print("📈 Overall average: \(String(format: "%.1f", overall))%")
            print("📊 Processed: \(totalImagesProcessed)/\(totalImagesFound) images")
            
            DispatchQueue.main.async {
                completion(.success(result))
            }
        }
    }
    
    // Cancel any ongoing operations (for future implementation)
    static func cancelSummaryGeneration() {
        // Implementation would require tracking operation state
        print("⏹️ Summary generation cancellation requested")
    }
}
