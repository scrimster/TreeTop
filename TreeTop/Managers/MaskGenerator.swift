import Foundation
import CoreML
import UIKit
import Vision

class MaskGenerator {
    static let shared = MaskGenerator()
    private let model: MLModel?

    private init() {
        // When .mlpackage models are added to an Xcode target they are
        // automatically compiled to a `.mlmodelc` directory inside the app
        // bundle.  Loading the original `.mlpackage` will fail because it is
        // not copied into the bundle.  Look for the compiled model instead.
        if let url = Bundle.main.url(forResource: "imageseg_canopy_model", withExtension: "mlmodelc") {
            model = try? MLModel(contentsOf: url)
        } else {
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
            if let maskImage = UIImage.grayImage(from: pixels, width: 256, height: 256) {
                return (maskImage, mean)
            }
        } catch {
            print("Mask generation failed: \(error)")
        }
        return nil
    }
}
