//
//  GPSBatchExtractor.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 8/3/25.
//

import Foundation

struct GPSBatchExtractor {
    static func extractEndpoints(from folderURL: URL) -> (start: Coordinate?, end: Coordinate?) {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles])
            
            let imageFiles = contents.filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "jpeg" || $0.pathExtension.lowercased() == "png" }
            
            guard !imageFiles.isEmpty else {
                print("📂 No image files found in: \(folderURL.lastPathComponent)")
                return (nil, nil)
            }
            
            // Sort alphabetically or by modification date
            let sorted = try imageFiles.sorted {
                let attr0 = try $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                let attr1 = try $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                return attr0 < attr1
            }
            
            let firstURL = sorted.first!
            let lastURL = sorted.last!
            
            let start = ImageMDReader.extract(from: firstURL)
            let end = ImageMDReader.extract(from: lastURL)
            
            print("✅ Extracted start from: \(firstURL.lastPathComponent), end from: \(lastURL.lastPathComponent)")
            return (start, end)
            
        } catch {
            print("❌ Error reading folder contents at \(folderURL.path): \(error)")
            return (nil, nil)
        }
    }
}
