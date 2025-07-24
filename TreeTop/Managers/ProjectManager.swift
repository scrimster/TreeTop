//
//  ProjectManager.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/23/25.
//

import Foundation
import SwiftData
import UIKit

class ProjectManager {
    static var shared: ProjectManager! //allows the instance to access the ProjectManage from anywhere
    
    let modelContext: ModelContext
    private let initializationQueue = DispatchQueue(label: "com.treetop.projectmanager", qos: .userInitiated)
    
    //initializes the manage with the given SwiftData model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("✅ ProjectManager initialized successfully")
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
            print("✅ ProjectManager data preloaded")
        } catch {
            print("⚠️ Failed to preload ProjectManager data: \(error)")
        }
    }
    
    
    
    //this creates a unique folder name using the project name the user inputs and creates a new UUID
    func createProject(name: String, date: Date) -> Project? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            print("Project name is empty or only whitespace.")
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
                print("Duplicate project name detected")
                return nil
            }
        } catch {
            print("Failed to check for duplicate projects: \(error)")
            return nil
            
        }
        
        let folderName = "\(trimmedName) - \(UUID().uuidString)"
        let newProject = Project(name: name, date: date, folderName: folderName) //intializes the instance
        
        let folderURL = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0].appendingPathComponent(folderName) //creates the URL for the project's folder
        
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
            modelContext.insert(newProject) //inserts the new project into the SwiftData model
            print("New project created successfully")
            return newProject
        } catch {
            print("Failed to create folder: \(error)")
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
            print("Failed to delete folder: \(error.localizedDescription)")
        }
    }
    
    //creating the function to save the captured photos to the subfolder content view

    func saveImage(_ image: UIImage, to project: Project, inSubFolder subfolder: String, type: String = "Photos") -> Bool {
        let folderURL: URL?
        
        if type == "Photos" {
            folderURL = project.photoFolderURL(forDiagonal: subfolder)
        } else if type == "Masks" {
            folderURL = project.maskFolderURL(forDiagonal: subfolder)
        } else {
            print("Invalid image type. Must be 'Photos' or 'Masks'.")
            return false
        }
//        guard let folderURL = project.viewContentsURL(forSubfolder: subfolder) else {
//            print("Invalid subfolder path.")
//            return false
//        }
        
        guard let folderURL = folderURL else {
            print("Invalid subfolder path.")
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
            print("Image saved to folder: \(fileURL.path)")
            return true
        } catch {
            print("Error saving image: \(error)")
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
}
