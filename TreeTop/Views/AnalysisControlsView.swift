//
//  AnalysisControlsView.swift
//  TreeTop
//
//  Created by TreeTop Assistant on 7/20/25.
//

import SwiftUI
import SwiftData
import Foundation

/// Controls for running canopy analysis and exporting results
struct AnalysisControlsView: View {
    let project: Project?
    let folderURL: URL?
    let onAnalysisComplete: (SummaryResult) -> Void
    let onAnalysisError: (String) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @State private var isGeneratingSummary = false
    @State private var isExportingPDF = false
    @State private var summaryProgress: (current: Int, total: Int) = (0, 0)
    @State private var summaryProgressMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Run Canopy Analysis Button
            Button(action: {
                guard let url = folderURL, !isGeneratingSummary else { return }
                if let project = project, project.needsPhotos { return }
                deleteAllMasks(projectURL: url)
                isGeneratingSummary = true
                summaryProgress = (0, 0)
                summaryProgressMessage = "Initializing…"
                
                SummaryGenerator.createSummaryAsync(
                    forProjectAt: url,
                    progressCallback: { message, current, total in
                        DispatchQueue.main.async {
                            summaryProgress = (current, total)
                            summaryProgressMessage = message
                        }
                    },
                    completion: { result in
                        DispatchQueue.main.async {
                            isGeneratingSummary = false
                            switch result {
                            case .success(let summary):
                                onAnalysisComplete(summary)
                                if let project = project {
                                    project.canopyCoverPercentage = summary.overallAverage
                                    project.lastAnalysisDate = Date()
                                    project.diagonal1Percentage = summary.diagonalAverages["Diagonal 1"]
                                    project.diagonal2Percentage = summary.diagonalAverages["Diagonal 2"]
                                    try? modelContext.save()
                                }
                            case .failure(let error):
                                onAnalysisError(error.localizedDescription)
                            }
                        }
                    }
                )
            }) {
                Label(isGeneratingSummary ? "Running Analysis…" : "Run Canopy Analysis", systemImage: "chart.bar.doc.horizontal")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGeneratingSummary || project?.needsPhotos == true)
            
            // Analysis Progress
            if isGeneratingSummary {
                VStack(spacing: 8) {
                    ProgressView(value: Double(summaryProgress.current), total: Double(summaryProgress.total))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    Text(summaryProgressMessage)
                        .font(.caption)
                        .glassTextSecondary()
                    if summaryProgress.total > 0 {
                        Text("\(summaryProgress.current) / \(summaryProgress.total) images processed")
                            .font(.caption2)
                            .glassTextSecondary()
                    }
                    Button("Cancel Analysis") {
                        isGeneratingSummary = false
                        SummaryGenerator.cancelSummaryGeneration()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Export PDF Button
            Button(action: {
                guard let project = project, !isExportingPDF else { return }
                isExportingPDF = true
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let url = try PDFExportManager.shared.exportProjectReport(for: project)
                        DispatchQueue.main.async {
                            // Handle successful export
                            isExportingPDF = false
                        }
                    } catch {
                        DispatchQueue.main.async {
                            onAnalysisError(error.localizedDescription)
                            isExportingPDF = false
                        }
                    }
                }
            }) {
                Label(isExportingPDF ? "Exporting…" : "Export PDF", systemImage: "doc.richtext")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(isExportingPDF)
        }
    }
    
    private func deleteAllMasks(projectURL: URL) {
        let fileManager = FileManager.default
        
        // Delete masks from Diagonal 1
        let diagonal1MasksURL = projectURL.appendingPathComponent("Diagonal 1").appendingPathComponent("Masks")
        deleteMasksInDirectory(url: diagonal1MasksURL, fileManager: fileManager)
        
        // Delete masks from Diagonal 2
        let diagonal2MasksURL = projectURL.appendingPathComponent("Diagonal 2").appendingPathComponent("Masks")
        deleteMasksInDirectory(url: diagonal2MasksURL, fileManager: fileManager)
    }
    
    private func deleteMasksInDirectory(url: URL, fileManager: FileManager) {
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        do {
            let maskFiles = try fileManager.contentsOfDirectory(atPath: url.path)
            
            for maskFile in maskFiles {
                let maskFileURL = url.appendingPathComponent(maskFile)
                
                // Only delete image files (masks)
                if maskFile.lowercased().hasSuffix(".png") || 
                   maskFile.lowercased().hasSuffix(".jpg") || 
                   maskFile.lowercased().hasSuffix(".jpeg") {
                    try fileManager.removeItem(at: maskFileURL)
                }
            }
        } catch {
            // Silently handle deletion errors
        }
    }
}

#Preview {
    AnalysisControlsView(
        project: nil,
        folderURL: nil,
        onAnalysisComplete: { _ in },
        onAnalysisError: { _ in }
    )
    .background(AnimatedForestBackground())
}
