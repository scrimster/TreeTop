//
//  ProjectManager.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/23/25.
//

import Foundation
import SwiftData
import UIKit
import CoreLocation

class ProjectManager {
    static var shared: ProjectManager! /// Shared instance for global access
    
    let modelContext: ModelContext
    private let initializationQueue = DispatchQueue(label: "com.treetop.projectmanager", qos: .userInitiated)
    
    // Initializes the manager with the given SwiftData model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Pre-warm any expensive operations
    func preloadData() {
        // Ensure we're on the main thread for ModelContext operations
        if Thread.isMainThread {
            performPreload()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.performPreload()
            }
        }
    }
    
    private func performPreload() {
        // Pre-load project count to warm up SwiftData
        do {
            var fetchDescriptor = FetchDescriptor<Project>()
            fetchDescriptor.fetchLimit = 1
            let _ = try self.modelContext.fetch(fetchDescriptor)
        } catch {
            // Silently handle preload errors
        }
    }
    
    
    
    /// Creates a new project with a unique folder structure
    func createProject(name: String, date: Date) -> Project? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return nil
        }
        
        let normalizedName = trimmedName.lowercased()
        
        let fetchDescriptor = FetchDescriptor<Project>()
        
        do {
            let existingProjects = try modelContext.fetch(fetchDescriptor)
            let nameExists = existingProjects.contains {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedName
            }
            
            if nameExists {
                return nil
            }
        } catch {
            return nil
        }
        
        let folderName = "\(trimmedName) - \(UUID().uuidString)"
        let newProject = Project(
            name: name,
            date: date,
            folderName: folderName,
            location: nil,
            latitude: 0.0,
            longitude: 0.0,
            elevation: 0.0
        )
        
        let folderURL = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0].appendingPathComponent(folderName)
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let diagonalNames = ["Diagonal 1", "Diagonal 2"]
            for name in diagonalNames {
                let subfolderURL = folderURL.appendingPathComponent(name)
                try FileManager.default.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
                    
                    let photosURL = subfolderURL.appendingPathComponent("Photos")
                    let masksURL = subfolderURL.appendingPathComponent("Masks")
                    try FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
                    try FileManager.default.createDirectory(at: masksURL, withIntermediateDirectories: true)
            }
            
            modelContext.insert(newProject) // Inserts the new project into the SwiftData model
            return newProject
        } catch {
            return nil
        }
    }
    
    func delete(_ project: Project) {
        modelContext.delete(project)
        
        do {
            if let folderURL = project.folderURL {
                if FileManager.default.fileExists(atPath: folderURL.path) {
                    try FileManager.default.removeItem(at: folderURL)
                }
            }
        } catch {
            // Silently handle folder deletion errors
        }
    }
    
    /// Saves captured images to the specified project subfolder

    func saveImage(_ image: UIImage, to project: Project, inSubFolder subfolder: String, type: String = "Photos") -> Bool {
        let folderURL: URL?
        
        if type == "Photos" {
            folderURL = project.photoFolderURL(forDiagonal: subfolder)
        } else if type == "Masks" {
            folderURL = project.maskFolderURL(forDiagonal: subfolder)
        } else {
            return false
        }
//        guard let folderURL = project.viewContentsURL(forSubfolder: subfolder) else {
//            print("Invalid subfolder path.")
//            return false
//        }
        
        guard let folderURL = folderURL else {
            return false
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        
        let fileName = "image_\(dateFormatter.string(from: Date())).jpg"
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            return false
        }
        
        do {
            try imageData.write(to: fileURL)
            
            // Refresh project statistics after saving image
            refreshProjectStatistics(project)
            
            return true
        } catch {
            return false
        }
    }
    
    func loadImages(for project: Project) -> [UIImage] {
        var images: [UIImage] = []
        
        let folderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) [0] .appendingPathComponent(project.folderName)
        if let fileURLs = try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) {
            for fileURL in fileURLs {
                if let image = UIImage(contentsOfFile: fileURL.path) {
                    images.append(image)
                }
            }
        }
        return images
    }
    
    // MARK: - Project Statistics Methods
    
    func refreshProjectStatistics(_ project: Project) {
        ProjectStatisticsManager.shared.updateProjectStatistics(project)
        try? modelContext.save()
    }
    
    func updateProjectAnalysis(_ project: Project, canopyPercentage: Double) {
        ProjectStatisticsManager.shared.updateCanopyCoverPercentage(project, percentage: canopyPercentage)
        try? modelContext.save()
    }
    
    // MARK: - Center Reference Photo Management
    
    func saveCenterReferencePhoto(_ image: UIImage, to project: Project, location: CLLocation?) -> Bool {
        // Create center reference directory if it doesn't exist
        guard let projectFolderURL = project.folderURL else {
            // Failed to get project folder URL
            return false
        }
        
                    // Project folder URL retrieved
        
        // Generate filename with timestamp
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = "center_reference_\(formatter.string(from: timestamp)).jpg"
        let thumbnailFileName = "thumb_\(fileName)"
        
        // Save directly in project folder
        let imageURL = projectFolderURL.appendingPathComponent(fileName)
        let thumbnailURL = projectFolderURL.appendingPathComponent(thumbnailFileName)
        
                    // Saving center reference image
        
        // Save full-size image
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            // Failed to convert image to JPEG data
            return false
        }
        
        do {
            try imageData.write(to: imageURL)
            // Center reference image saved successfully
        } catch {
            // Failed to save center reference image
            return false
        }
        
        // Create and save thumbnail (300x300)
        let thumbnailSize = CGSize(width: 300, height: 300)
        if let thumbnail = image.centerSquareCrop(to: thumbnailSize),
           let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) {
            do {
                try thumbnailData.write(to: thumbnailURL)
                // Center reference thumbnail saved successfully
            } catch {
                // Failed to save thumbnail (non-critical)
            }
        }
        
        // Update project properties
        project.centerImageFileName = fileName
        project.centerImageDate = timestamp
        
        if let location = location {
            project.centerImageLatitude = location.coordinate.latitude
            project.centerImageLongitude = location.coordinate.longitude
            project.centerImageElevation = location.altitude
            // Also reflect elevation in the main project elevation field for overview displays
            project.elevation = location.altitude
            // Location data saved for center reference
        }
        
        // Save project changes
        do {
            try modelContext.save()
            // Project updated with center reference data
            return true
        } catch {
            // Failed to save project updates
            return false
        }
    }
    
    func getCenterReferenceImage(for project: Project) -> UIImage? {
        guard let imageURL = project.centerReferenceImageURL(),
              FileManager.default.fileExists(atPath: imageURL.path) else {
            return nil
        }
        
        return UIImage(contentsOfFile: imageURL.path)
    }
    
    func getCenterReferenceThumbnail(for project: Project) -> UIImage? {
        guard let thumbnailURL = project.centerReferenceThumbnailURL(),
              FileManager.default.fileExists(atPath: thumbnailURL.path) else {
            // Fallback to full image if thumbnail doesn't exist
            return getCenterReferenceImage(for: project)
        }
        
        return UIImage(contentsOfFile: thumbnailURL.path)
    }
    
    func deleteCenterReference(for project: Project) -> Bool {
        guard let imageURL = project.centerReferenceImageURL() else { return false }
        
        do {
            // Delete full image
            if FileManager.default.fileExists(atPath: imageURL.path) {
                try FileManager.default.removeItem(at: imageURL)
            }
            
            // Delete thumbnail if it exists
            if let thumbnailURL = project.centerReferenceThumbnailURL(),
               FileManager.default.fileExists(atPath: thumbnailURL.path) {
                try FileManager.default.removeItem(at: thumbnailURL)
            }
            
            // Clear project properties
            project.centerImageFileName = nil
            project.centerImageDate = nil
            project.centerImageLatitude = nil
            project.centerImageLongitude = nil
            project.centerImageElevation = nil
            
            try modelContext.save()
            // Center reference deleted for project
            return true
            
        } catch {
            // Failed to delete center reference
            return false
        }
    }


}
