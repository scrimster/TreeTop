import UIKit
import CoreVideo
import Accelerate

extension UIImage {
    // Optimized resizing with better memory management
    func resized(to size: CGSize) -> UIImage? {
        // Avoid resizing if already the correct size
        if self.size == size {
            return self
        }
        
        // Use a more memory-efficient approach for large images
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // Center square crop - better for canopy analysis than squeezing
    func centerSquareCrop() -> UIImage? {
        let currentSize = self.size
        let sideLength = min(currentSize.width, currentSize.height)
        
        let cropRect = CGRect(
            x: (currentSize.width - sideLength) / 2,
            y: (currentSize.height - sideLength) / 2,
            width: sideLength,
            height: sideLength
        )
        
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
    }
    
    // Center square crop and resize to specific size - ideal for ML processing
    func centerSquareCrop(to targetSize: CGSize) -> UIImage? {
        return self.centerSquareCrop()?.resized(to: targetSize)
    }

    // Optimized pixel buffer conversion with error handling
    func toPixelBuffer() -> CVPixelBuffer? {
        guard size.width > 0 && size.height > 0 else {
            print("❌ Invalid image dimensions: \(size)")
            return nil
        }
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue! // For better GPU performance
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("❌ Failed to create pixel buffer, status: \(status)")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                     width: Int(size.width),
                                     height: Int(size.height),
                                     bitsPerComponent: 8,
                                     bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                     space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            print("❌ Failed to create CGContext for pixel buffer")
            return nil
        }
        
        if let cgImage = cgImage {
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        } else {
            print("⚠️ No CGImage available for pixel buffer conversion")
            return nil
        }
        
        return buffer
    }

    // Optimized grayscale image creation
    static func grayImage(from pixels: [UInt8], width: Int, height: Int) -> UIImage? {
        guard pixels.count == width * height else { 
            print("❌ Pixel array size mismatch: expected \(width * height), got \(pixels.count)")
            return nil 
        }
        
        guard width > 0 && height > 0 else {
            print("❌ Invalid image dimensions: \(width)x\(height)")
            return nil
        }
        
        let data = Data(pixels)
        guard let providerRef = CGDataProvider(data: data as CFData) else {
            print("❌ Failed to create data provider")
            return nil
        }
        
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let cgImage = CGImage(width: width,
                                   height: height,
                                   bitsPerComponent: 8,
                                   bitsPerPixel: 8,
                                   bytesPerRow: width,
                                   space: colorSpace,
                                   bitmapInfo: CGBitmapInfo(rawValue: 0),
                                   provider: providerRef,
                                   decode: nil,
                                   shouldInterpolate: false,
                                   intent: .defaultIntent) else {
            print("❌ Failed to create CGImage from grayscale data")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Additional helper for memory-efficient loading from file
    static func loadImageOptimized(from path: String, maxSize: CGSize? = nil) -> UIImage? {
        guard FileManager.default.fileExists(atPath: path) else {
            print("❌ Image file not found: \(path)")
            return nil
        }
        
        guard let image = UIImage(contentsOfFile: path) else {
            print("❌ Failed to load image from: \(path)")
            return nil
        }
        
        // Resize if needed to save memory
        if let maxSize = maxSize, (image.size.width > maxSize.width || image.size.height > maxSize.height) {
            let aspectRatio = image.size.width / image.size.height
            let newSize: CGSize
            
            if aspectRatio > 1 {
                // Landscape
                newSize = CGSize(width: min(maxSize.width, image.size.width), 
                               height: min(maxSize.width / aspectRatio, image.size.height))
            } else {
                // Portrait
                newSize = CGSize(width: min(maxSize.height * aspectRatio, image.size.width), 
                               height: min(maxSize.height, image.size.height))
            }
            
            return image.resized(to: newSize)
        }
        
        return image
    }
}
