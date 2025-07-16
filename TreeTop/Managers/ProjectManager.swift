//
//  ProjectManager.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/23/25.
//

import Foundation
import SwiftData
import UIKit

// I think we need to modify project manager to make it look more like how stephanie's location manager, where the newproject view just like how she has welcomeView and uses an env obj and creates an instance of the manager

class ProjectManager {
    static var shared: ProjectManager! //allows the instance to access the ProjectManage from anywhere
    
    let modelContext: ModelContext
    
    //initializes the manage with the given SwiftData model context
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    
    
    //this creates a unique folder name using the project name the user inputs and creates a new UUID
    func createProject(name: String, date: Date) -> Project? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let fetchDescriptor = FetchDescriptor<Project>()
        
        do {
            let existingProjects = try modelContext.fetch(fetchDescriptor)
            let nameExists = existingProjects.contains {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedName
            }
            
            if nameExists {
                print("Duplicate project name detected")
                return nil
            }
        } catch {
            print("Failed to check for duplicate projects: \(error)")
            return nil
            
        }
        
        let folderName = "\(name) - \(UUID().uuidString)"
        let newProject = Project(name: name, date: date, folderName: folderName) //intializes the instance
        
        let folderURL = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0].appendingPathComponent(folderName) //creates the URL for the project's folder
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let diagonalNames = ["Diagonal 1", "Diagonal 2"]
            for name in diagonalNames {
                if let projectFolder = newProject.folderURL {
                    let subfolderURL = projectFolder.appendingPathComponent(name)
                    try FileManager.default.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
                    
                    let photosURL = subfolderURL.appendingPathComponent("Photos")
                    let masksURL = subfolderURL.appendingPathComponent("Masks")
                    try FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
                    try FileManager.default.createDirectory(at: masksURL, withIntermediateDirectories: true)
                    
//                   let viewContentsURL = newProject.viewContentsURL(forSubfolder: name) {
//                    try FileManager.default.createDirectory(at: subfolderURL, withIntermediateDirectories: true)
//                    try FileManager.default.createDirectory(at: viewContentsURL, withIntermediateDirectories: true)
//
//                    let photosURL = viewContentsURL.appendingPathComponent("Photos")
//                    let masksURL = viewContentsURL.appendingPathComponent("Masks")
//                    try FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
//                    try FileManager.default.createDirectory(at: masksURL, withIntermediateDirectories: true)
                }
            }
            modelContext.insert(newProject) //inserts the new project into the SwiftData model
            print("New project created successfully")
            return newProject
        } catch {
            print("Failed to create folder: \(error)")
            return nil
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
