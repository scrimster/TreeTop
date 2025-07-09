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

            // create sub folders for diagonals
            let d1 = folderURL.appendingPathComponent("Diagonal1")
            let d2 = folderURL.appendingPathComponent("Diagonal2")
            let subFolders = [
                d1.appendingPathComponent("Originals"),
                d1.appendingPathComponent("Masks"),
                d2.appendingPathComponent("Originals"),
                d2.appendingPathComponent("Masks")
            ]
            for url in subFolders {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }

            modelContext.insert(newProject) //inserts the new project into the SwiftData model
            print("New project created successfully")
            return newProject
        } catch {
            print("Failed to create folder: \(error)")
            return nil
        }
    }

    //creating the function to save the captured photo to the newly created project folder
    func saveImage(_ image: UIImage, to project:Project, subfolder: String? = nil) -> Bool{
        var folderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask) [0] .appendingPathComponent(project.folderName)
        if let subfolder = subfolder {
            folderURL.appendPathComponent(subfolder)
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

    func analyzeImages(in diagonal: String, for project: Project) -> Double? {
        guard let originals = project.folderURL?.appendingPathComponent(diagonal).appendingPathComponent("Originals"),
              let masksFolder = project.folderURL?.appendingPathComponent(diagonal).appendingPathComponent("Masks") else { return nil }
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: originals.path) else { return nil }

        var totals: [Double] = []

        for file in files where file.lowercased().hasSuffix(".jpg") {
            let imageURL = originals.appendingPathComponent(file)
            let maskURL = masksFolder.appendingPathComponent(file)
            if let avg = runModel(inputURL: imageURL, outputURL: maskURL) {
                totals.append(avg)
            }
        }

        guard !totals.isEmpty else { return nil }
        return totals.reduce(0, +) / Double(totals.count)
    }

    func createSummary(for project: Project) -> Double? {
        let d1 = analyzeImages(in: "Diagonal1", for: project)
        let d2 = analyzeImages(in: "Diagonal2", for: project)
        var values: [Double] = []
        if let d1 = d1 { values.append(d1) }
        if let d2 = d2 { values.append(d2) }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func runModel(inputURL: URL, outputURL: URL) -> Double? {
        // Placeholder for CoreML processing. Replace with real model inference.
        guard let image = UIImage(contentsOfFile: inputURL.path) else { return nil }
        guard let data = image.pngData() else { return nil }
        do {
            try data.write(to: outputURL)
        } catch {
            print("failed to write mask: \(error)")
        }
        // Pretend 50% canopy
        return 0.5
    }
}
