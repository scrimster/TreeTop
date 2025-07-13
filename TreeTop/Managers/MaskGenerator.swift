import Foundation
import CoreML
import UIKit
import Vision

class MaskGenerator {
    static let shared = MaskGenerator()
    private let model: MLModel?

    private init() {
        // When a .mlpackage is added to an Xcode target it is typically
        // compiled to a `.mlmodelc` directory within the app bundle.
        // Depending on how the project is configured the compiled directory
        // may not be present, but the original .mlpackage might be copied
        // instead.  Try to load the compiled model first and fall back to
        // compiling the package at runtime if needed.
        if let compiledURL = Bundle.main.url(forResource: "imageseg_canopy_model", withExtension: "mlmodelc") {
            model = try? MLModel(contentsOf: compiledURL)
        } else if let packageURL = Bundle.main.url(forResource: "imageseg_canopy_model", withExtension: "mlpackage") {
            if let tempURL = try? MLModel.compileModel(at: packageURL) {
                model = try? MLModel(contentsOf: tempURL)
            } else {
                print("[MaskGenerator] Failed to compile mlpackage")
                model = nil
            }
        } else {
            print("[MaskGenerator] Model not found in bundle")
            model = nil
        }
    }

    func generateMask(for image: UIImage) -> (mask: UIImage, skyMean: Double)? {
        guard let model = model,
              let resized = image.resized(to: CGSize(width: 256, height: 256)),
              let buffer = resized.toPixelBuffer() else { return nil }
        do {
            let outFeatures = try model.prediction(from: MLDictionaryFeatureProvider(dictionary: ["input_img": buffer]))
            guard let multiArray = outFeatures.featureValue(for: "Identity")?.multiArrayValue else { return nil }
            let count = multiArray.count
            var pixels = [UInt8](repeating: 0, count: count)
            var sum: Double = 0
            for i in 0..<count {
                let val = multiArray[i].doubleValue
                sum += val
                pixels[i] = UInt8(min(255, max(0, Int(val * 255))))
            }
            let mean = sum / Double(count)
            let shape = multiArray.shape.map { $0.intValue }
            let width: Int
            let height: Int
            if shape.count >= 2 {
                width = shape[shape.count - 2]
                height = shape[shape.count - 1]
            } else {
                width = 256
                height = 256
            }
            if let maskImage = UIImage.grayImage(from: pixels, width: width, height: height) {
                return (maskImage, mean)
            }
        } catch {
            print("Mask generation failed: \(error)")
        }
        return nil
    }
}
