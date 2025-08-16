//
//  ProjectStatisticsManager.swift
//  TreeTop
//
//

import Foundation
import SwiftData

class ProjectStatisticsManager {
    static let shared = ProjectStatisticsManager()
    
    private init() {}
    
    /// Updates all statistics for a project
    func updateProjectStatistics(_ project: Project) {
        updatePhotoCounts(project)
        updateLastPhotoModifiedDate(project)
        // Canopy percentage would be updated after AI analysis
    }
    
    /// Updates photo counts for diagonals
    private func updatePhotoCounts(_ project: Project) {
        guard let folderURL = project.folderURL else {
            project.diagonal1Photos = 0
            project.diagonal2Photos = 0
            project.totalPhotos = 0
            return
        }
        
        let diagonal1URL = folderURL.appendingPathComponent("Diagonal 1").appendingPathComponent("Photos")
        let diagonal2URL = folderURL.appendingPathComponent("Diagonal 2").appendingPathComponent("Photos")
        
        project.diagonal1Photos = countPhotosInFolder(diagonal1URL)
        project.diagonal2Photos = countPhotosInFolder(diagonal2URL)
        project.totalPhotos = project.diagonal1Photos + project.diagonal2Photos
    }
    
    /// Updates the last photo modified date
    private func updateLastPhotoModifiedDate(_ project: Project) {
        guard let folderURL = project.folderURL else {
            project.lastPhotoModifiedDate = nil
            return
        }
        
        var latestDate: Date?
        
        let diagonal1URL = folderURL.appendingPathComponent("Diagonal 1").appendingPathComponent("Photos")
        let diagonal2URL = folderURL.appendingPathComponent("Diagonal 2").appendingPathComponent("Photos")
        
        for folderURL in [diagonal1URL, diagonal2URL] {
            if let photos = try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.contentModificationDateKey]) {
                for photoURL in photos where photoURL.pathExtension.lowercased() == "jpg" {
                    if let modDate = try? photoURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate {
                        if latestDate == nil || modDate > latestDate! {
                            latestDate = modDate
                        }
                    }
                }
            }
        }
        
        project.lastPhotoModifiedDate = latestDate
    }
    
    /// Updates canopy cover percentage after AI analysis
    func updateCanopyCoverPercentage(_ project: Project, percentage: Double) {
        project.canopyCoverPercentage = percentage
        project.lastAnalysisDate = Date()
    }
    
    /// Adds custom statistic for future expansion
    func addCustomStatistic(_ project: Project, key: String, value: Double) {
        // Custom statistics feature not yet implemented
        print("Custom statistic: \(key) = \(value)")
    }
    
    private func countPhotosInFolder(_ folderURL: URL) -> Int {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) else {
            return 0
        }
        
        return contents.filter { $0.pathExtension.lowercased() == "jpg" }.count
    }
}
