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
        let folderName = "\(name) - \(UUID().uuidString)"
        let newProject = Project(name: name, date: date, folderName: folderName) //intializes the instance
        
        let folderURL = FileManager.default.urls(for:.documentDirectory, in: .userDomainMask)[0].appendingPathComponent(folderName) //creates the URL for the project's folder
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            modelContext.insert(newProject) //inserts the new project into the SwiftData model
            print("New project created successfully")
            return newProject
        } catch {
            print("Failed to create folder: \(error)")
            return nil
        }
    }
    
    //creating the function to save the captured photo to the newly created project folder
    func saveImage(_ image: UIImage, to project:Project) -> Bool{
        let folderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) [0] .appendingPathComponent(project.folderName)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        
        let fileName = "image_\(dateFormatter.string(from: Date())).jpg"
        let fileURL = folderURL.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            return false
        }
        
        do {
            try imageData.write(to: fileURL)
            print("Image saved to folder")
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
