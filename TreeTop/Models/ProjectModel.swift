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
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var elevation: Double = 0.0
    var weatherSummary: String = ""
    var location: LocationModel?
    var imagePaths: [String] = [] //stores the file paths as string to any images associated with the project. when the user adds a photo, we'll save it to disk and append the file path

    
    //defining an initialization to create a new project
    init(
        name: String,
        date: Date,
        folderName: String,
        location: LocationModel?,
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        elevation: Double = 0.0,
        weatherSummary: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.folderName = folderName
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.weatherSummary = weatherSummary
    }
    
    var folderURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(folderName)
    }
    
    func photoFolderURL(forDiagonal diagonal: String) -> URL? {
        return folderURL?.appendingPathComponent(diagonal).appendingPathComponent("Photos")
    }
    
    func maskFolderURL(forDiagonal diagonal: String) -> URL? {
        return folderURL?.appendingPathComponent(diagonal).appendingPathComponent("Masks")
    }
}
