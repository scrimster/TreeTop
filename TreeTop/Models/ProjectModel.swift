//
//  Project.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/24/25.
//

import Foundation
import SwiftData

@Model
//creating the blueprint to what a single project is in the app
class Project {
    var id: UUID
    var name: String //will store the name the user enters when creating a project
    var date: Date //stores the full date and time the user selects when creating the project
    var folderName: String
    
    //@Attribute(.transformable(by: StringArrayTransformer.self))
    var imagePaths: [String] = [] //stores the file paths as string to any images associated with the project. when the user adds a photo, we'll save it to disk and append the file path
    
    //@Attribute(.transformable(by: DoubleArrayTransformer.self))
    //var canopyCoverageResults: [Double] = [] //store the percentage canopy coverage values
    
    //defining an initialization to create a new project
    init(name: String, date: Date, folderName: String) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.folderName = folderName
        //self.imagePaths = []
    }
    
    var folderURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(folderName)
    }
    
    func subFolderURL(named subfolder: String) -> URL? {
        return folderURL?.appendingPathComponent(subfolder)
    }
    
    func viewContentsURL(forSubfolder subfolder: String) -> URL? {
        return subFolderURL(named: subfolder)?.appendingPathComponent("View Contents")
    }
}
