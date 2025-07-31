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
    
    // Project statistics fields
    var canopyCoverPercentage: Double?
    var lastAnalysisDate: Date?
    var lastPhotoModifiedDate: Date?
    var totalPhotos: Int = 0
    var diagonal1Photos: Int = 0
    var diagonal2Photos: Int = 0
    var additionalStats: [String: Double] = [:] // For future API data
    
    // Analysis results storage - simplified for SwiftData compatibility
    var diagonal1Percentage: Double?
    var diagonal2Percentage: Double?
    
    // Computed property to check if analysis has been performed
    var hasAnalysisResults: Bool {
        return canopyCoverPercentage != nil && (diagonal1Percentage != nil || diagonal2Percentage != nil)
    }
    
    // Computed property to check if analysis is out of date
    var isAnalysisOutOfDate: Bool {
        // If no photos at all, not out of date (need photos first)
        if totalPhotos == 0 { return false }
        
        guard let analysisDate = lastAnalysisDate,
              let photoDate = lastPhotoModifiedDate else { return true }
        return photoDate > analysisDate
    }
    
    // Computed property to check if photos are needed
    var needsPhotos: Bool {
        return totalPhotos == 0
    }
    
    // Computed property to check if missing diagonal photos
    var hasMissingDiagonal: Bool {
        return (diagonal1Photos == 0 && diagonal2Photos > 0) || 
               (diagonal2Photos == 0 && diagonal1Photos > 0)
    }
    
    // Computed property to get missing diagonal name
    var missingDiagonalName: String? {
        if diagonal1Photos == 0 && diagonal2Photos > 0 {
            return "Diagonal 1"
        } else if diagonal2Photos == 0 && diagonal1Photos > 0 {
            return "Diagonal 2"
        }
        return nil
    }
    
    // Computed property to get SummaryResult from stored data
    var storedSummaryResult: SummaryResult? {
        guard let overallAverage = canopyCoverPercentage else { return nil }
        
        // Convert stored diagonal results back to the format expected by SummaryResult
        var diagonalAverages: [String: Double] = [:]
        
        if let diag1 = diagonal1Percentage {
            diagonalAverages["Diagonal 1"] = diag1
        }
        if let diag2 = diagonal2Percentage {
            diagonalAverages["Diagonal 2"] = diag2
        }
        
        // Only return result if we have at least one diagonal
        guard !diagonalAverages.isEmpty else { return nil }
        
        return SummaryResult(
            diagonalAverages: diagonalAverages,
            overallAverage: overallAverage
        )
    }

    
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
