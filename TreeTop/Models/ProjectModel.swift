//
//  Project.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/24/25.
//

import Foundation

//creating the blueprint to what a single project is in the app
struct Project: Codable, Identifiable {
    let id: UUID //this gives each project a unique identifier
    var name: String //will store the name the user enters when creating a project
    var date: Date //stores the full date and time the user selects when creating the project
    var imagePaths: [String] //stores the file paths as string to any images associated with the project. when the user adds a photo, we'll save it to disk and append the file path
    var canopyCoverageResults: [Double] //store the percentage canopy coverage values
    
    //defining an initialization to create a new project
    init(name: String, date: Date) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.imagePaths = []
        self.canopyCoverageResults = []
    }
}
