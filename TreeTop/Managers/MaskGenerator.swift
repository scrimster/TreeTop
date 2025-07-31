import Foundation
import CoreML
import UIKit
import Vision

class MaskGenerator {
    static let shared = MaskGenerator()
    private let model: MLModel?
    private let modelQueue = DispatchQueue(label: "com.treetop.maskgeneration", qos: .userInitiated)
    
    // Configuration for preventing hanging
    private let maxProcessingTime: TimeInterval = 30.0 // 30 second timeout
    private var isProcessing = false

    private init() {
        // When .mlpackage models are added to an Xcode target they are
        // automatically compiled to a `.mlmodelc` directory inside the app
        // bundle.  Loading the original `.mlpackage` will fail because it is
        // not copied into the bundle.  Look for the compiled model instead.
        if let url = Bundle.main.url(forResource: "imageseg_canopy_model", withExtension: "mlmodelc") {
            do {
                // Configure model for optimal performance with fallback options
                let configuration = MLModelConfiguration()
                
                // Try Neural Engine first, then fallback to CPU+GPU if unavailable
                if #available(iOS 14.0, *) {
                    configuration.computeUnits = .all
                } else {
                    configuration.computeUnits = .cpuAndGPU
                }
                
                // Suppress ANE warnings if possible
                configuration.allowLowPrecisionAccumulationOnGPU = true
                
                model = try MLModel(contentsOf: url, configuration: configuration)
                print("✅ CoreML model loaded successfully with optimized configuration")
            } catch let configError {
                print("⚠️ Failed to load CoreML model with configuration (\(configError)), trying default config...")
                // Fallback to default configuration
                do {
                    model = try MLModel(contentsOf: url)
                    print("✅ CoreML model loaded with default configuration")
                } catch let defaultError {
                    print("❌ Failed to load CoreML model entirely: \(defaultError)")
                    model = nil
                }
            }
        } else {
            print("❌ CoreML model file not found in bundle")
            model = nil
        }
    }

    // Synchronous version with timeout protection
    func generateMask(for image: UIImage) -> (mask: UIImage, skyMean: Double)? {
        guard !isProcessing else {
            print("⚠️ Model is already processing another image")
            return nil
        }
        
        guard let model = model else {
            print("❌ CoreML model not available")
            return nil
        }
        
        let startTime = Date()
        isProcessing = true
        defer { isProcessing = false }
        
        // Pre-process image with memory management
        autoreleasepool {
            guard let resized = image.centerSquareCrop(to: CGSize(width: 256, height: 256)),
                  let _ = resized.toPixelBuffer() else { 
                print("❌ Failed to preprocess image")
                return
            }
            
            // Check timeout before running inference
            guard Date().timeIntervalSince(startTime) < maxProcessingTime else {
                print("⏰ Image preprocessing timeout")
                return
            }
        }
        
        guard let resized = image.centerSquareCrop(to: CGSize(width: 256, height: 256)),
              let buffer = resized.toPixelBuffer() else { return nil }
        
        do {
            // Run inference with timeout monitoring
            let predictionStartTime = Date()
            let outFeatures = try model.prediction(from: MLDictionaryFeatureProvider(dictionary: ["input_img": buffer]))
            let predictionTime = Date().timeIntervalSince(predictionStartTime)
            
            print("📊 Model inference completed in \(String(format: "%.2f", predictionTime))s")
            
            // Check for timeout after inference
            guard Date().timeIntervalSince(startTime) < maxProcessingTime else {
                print("⏰ Model inference timeout")
                return nil
            }
            
            guard let multiArray = outFeatures.featureValue(for: "Identity")?.multiArrayValue else { return nil }
            let count = multiArray.count
            var pixels = [UInt8](repeating: 0, count: count)
            var sum: Double = 0
            
            // Process results with progress tracking
            for i in 0..<count {
                if i % 10000 == 0 && Date().timeIntervalSince(startTime) > maxProcessingTime {
                    print("⏰ Post-processing timeout")
                    return nil
                }
                
                let val = multiArray[i].doubleValue
                sum += val
                pixels[i] = UInt8(min(255, max(0, Int(val * 255))))
            }
            
            let mean = sum / Double(count)
            if let maskImage = UIImage.grayImage(from: pixels, width: 256, height: 256) {
                let totalTime = Date().timeIntervalSince(startTime)
                print("✅ Mask generation completed in \(String(format: "%.2f", totalTime))s")
                return (maskImage, mean)
            }
        } catch {
            print("❌ Mask generation failed: \(error)")
        }
        return nil
    }
    
    // Async version for better UI responsiveness
    func generateMaskAsync(for image: UIImage, completion: @escaping (Result<(mask: UIImage, skyMean: Double), Error>) -> Void) {
        modelQueue.async { [weak self] in
            guard let self = self else { 
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "MaskGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "MaskGenerator instance deallocated"])))
                }
                return 
            }
            
            if let result = self.generateMask(for: image) {
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "MaskGenerator", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to generate mask"])))
                }
            }
        }
    }
    
    // Batch processing with progress callback
    func generateMasksForBatch(_ images: [UIImage], 
                              progressCallback: @escaping (Int, Int) -> Void,
                              completion: @escaping ([Result<(mask: UIImage, skyMean: Double), Error>]) -> Void) {
        modelQueue.async { [weak self] in
            guard let self = self else { 
                DispatchQueue.main.async {
                    completion([])
                }
                return 
            }
            
            var results: [Result<(mask: UIImage, skyMean: Double), Error>] = []
            
            for (index, image) in images.enumerated() {
                // Update progress on main thread
                DispatchQueue.main.async {
                    progressCallback(index + 1, images.count)
                }
                
                if let result = self.generateMask(for: image) {
                    results.append(.success(result))
                } else {
                    results.append(.failure(NSError(domain: "MaskGenerator", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to process image \(index)"])))
                }
                
                // Add small delay to prevent overwhelming the system
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            DispatchQueue.main.async {
                completion(results)
            }
        }
    }
}
