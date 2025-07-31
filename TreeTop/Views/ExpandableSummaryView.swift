//
//  ExpandableSummaryView.swift
//  TreeTop
//
//  Created by Assistant on 7/28/25.
//

import SwiftUI

struct ExpandableSummaryView: View {
    let result: SummaryResult?
    let project: Project?
    @State private var isExpanded: Bool = false
    let initiallyExpanded: Bool
    
    init(result: SummaryResult?, project: Project? = nil, initiallyExpanded: Bool = false) {
        self.result = result
        self.project = project
        self.initiallyExpanded = initiallyExpanded
        self._isExpanded = State(initialValue: initiallyExpanded)
    }
    
    var body: some View {
        LiquidGlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with expand/collapse
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analysis Summary")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .glassText()
                        
                        Text(result != nil ? "Overall Canopy Cover" : "Status")
                            .font(.system(.caption, design: .rounded))
                            .glassTextSecondary(opacity: 0.7)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let result = result {
                            HStack(spacing: 8) {
                                // Show status indicator if applicable
                                if let project = project {
                                    if project.needsPhotos {
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 12))
                                    } else if project.hasMissingDiagonal {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 12))
                                    } else if project.isAnalysisOutOfDate {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 12))
                                    }
                                }
                                
                                Text("\(Int(result.overallAverage))%")
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.3, green: 0.8, blue: 0.5),
                                                Color(red: 0.2, green: 0.7, blue: 0.4)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            // Status text showing freshness and photo status
                            if let project = project {
                                if project.needsPhotos {
                                    Text("Need Photos")
                                        .font(.system(.caption2, design: .rounded, weight: .medium))
                                        .foregroundColor(.blue)
                                        .opacity(0.8)
                                } else if project.hasMissingDiagonal {
                                    Text("Missing Diagonal")
                                        .font(.system(.caption2, design: .rounded, weight: .medium))
                                        .foregroundColor(.orange)
                                        .opacity(0.8)
                                } else {
                                    Text(project.isAnalysisOutOfDate ? "Out of Date" : "Current")
                                        .font(.system(.caption2, design: .rounded, weight: .medium))
                                        .foregroundColor(project.isAnalysisOutOfDate ? .orange : .green)
                                        .opacity(0.8)
                                }
                            }
                        } else {
                            Text("Pending")
                                .font(.system(.title2, design: .default, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Less" : "Details")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .glassTextSecondary(opacity: 0.8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Expanded content
                if isExpanded {
                    VStack(spacing: 12) {
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        if let result = result {
                            // Show appropriate warning based on project state
                            if let project = project {
                                if project.needsPhotos {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "camera.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 16))
                                            
                                            Text("Photos Required")
                                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                .foregroundColor(.blue)
                                            
                                            Spacer()
                                        }
                                        
                                        Text("Capture photos in both diagonal folders before running analysis.")
                                            .font(.system(.caption, design: .rounded))
                                            .glassTextSecondary(opacity: 0.8)
                                            .padding(.leading, 8)
                                    }
                                    .padding(.bottom, 8)
                                } else if project.hasMissingDiagonal {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                                .font(.system(size: 16))
                                            
                                            Text("Missing \(project.missingDiagonalName ?? "Diagonal")")
                                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                .foregroundColor(.orange)
                                            
                                            Spacer()
                                        }
                                        
                                        Text("Capture photos in \(project.missingDiagonalName ?? "the missing diagonal") for complete analysis results.")
                                            .font(.system(.caption, design: .rounded))
                                            .glassTextSecondary(opacity: 0.8)
                                            .padding(.leading, 8)
                                    }
                                    .padding(.bottom, 8)
                                } else if project.isAnalysisOutOfDate {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                                .font(.system(size: 16))
                                            
                                            Text("Analysis Out of Date")
                                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                                .foregroundColor(.orange)
                                            
                                            Spacer()
                                        }
                                        
                                        Text("Photos have been modified since the last analysis. Run a new analysis to get updated results.")
                                            .font(.system(.caption, design: .rounded))
                                            .glassTextSecondary(opacity: 0.8)
                                            .padding(.leading, 8)
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                            
                            // Diagonal breakdown when data is available
                            VStack(spacing: 8) {
                                Text("Diagonal Breakdown")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .glassText()
                                
                                ForEach(Array(result.diagonalAverages.keys.sorted()), id: \.self) { diagonal in
                                    if let average = result.diagonalAverages[diagonal] {
                                        DiagonalSummaryRow(
                                            diagonal: diagonal,
                                            percentage: average,
                                            showMiniProgress: true
                                        )
                                    }
                                }
                            }
                        } else {
                            // Information when no analysis has been run
                            VStack(spacing: 12) {
                                HStack {
                                    if let project = project, project.needsPhotos {
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.blue.opacity(0.8))
                                            .font(.system(size: 16))
                                        
                                        Text("Photos Required")
                                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                            .glassText()
                                    } else {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue.opacity(0.8))
                                            .font(.system(size: 16))
                                        
                                        Text("Analysis Required")
                                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                            .glassText()
                                    }
                                    
                                    Spacer()
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    if let project = project {
                                        if project.needsPhotos {
                                            Text("• Capture photos in both Diagonal 1 and Diagonal 2 folders")
                                                .font(.system(.caption, design: .rounded))
                                                .glassTextSecondary(opacity: 0.8)
                                            
                                            Text("• Use the Take Photo button to start photo capture")
                                                .font(.system(.caption, design: .rounded))
                                                .glassTextSecondary(opacity: 0.8)
                                        } else if project.hasMissingDiagonal {
                                            Text("• Capture photos in \(project.missingDiagonalName ?? "missing diagonal") folder")
                                                .font(.system(.caption, design: .rounded))
                                                .glassTextSecondary(opacity: 0.8)
                                            
                                            Text("• Then tap 'Run Canopy Analysis' for complete results")
                                                .font(.system(.caption, design: .rounded))
                                                .glassTextSecondary(opacity: 0.8)
                                        } else {
                                            Text("• Tap 'Run Canopy Analysis' to generate coverage data")
                                                .font(.system(.caption, design: .rounded))
                                                .glassTextSecondary(opacity: 0.8)
                                            
                                            Text("• Analysis may take several minutes to complete")
                                                .font(.system(.caption, design: .rounded))
                                                .glassTextSecondary(opacity: 0.8)
                                        }
                                    } else {
                                        Text("• Tap 'Run Canopy Analysis' to generate coverage data")
                                            .font(.system(.caption, design: .rounded))
                                            .glassTextSecondary(opacity: 0.8)
                                        
                                        Text("• Ensure both diagonal folders contain photos")
                                            .font(.system(.caption, design: .rounded))
                                            .glassTextSecondary(opacity: 0.8)
                                        
                                        Text("• Analysis may take several minutes to complete")
                                            .font(.system(.caption, design: .rounded))
                                            .glassTextSecondary(opacity: 0.8)
                                    }
                                }
                                .padding(.leading, 8)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct DiagonalSummaryRow: View {
    let diagonal: String
    let percentage: Double
    let showMiniProgress: Bool
    
    init(diagonal: String, percentage: Double, showMiniProgress: Bool = false) {
        self.diagonal = diagonal
        self.percentage = percentage
        self.showMiniProgress = showMiniProgress
    }
    
    var body: some View {
        HStack {
            // Diagonal indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(diagonalColor)
                    .frame(width: 8, height: 8)
                
                Text(diagonal)
                    .font(.system(.subheadline, design: .rounded))
                    .glassText()
            }
            
            Spacer()
            
            // Percentage with mini progress bar
            HStack(spacing: 8) {
                if showMiniProgress {
                    // Mini progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            Rectangle()
                                .fill(diagonalColor)
                                .frame(
                                    width: geometry.size.width * (percentage / 100),
                                    height: 4
                                )
                                .cornerRadius(2)
                        }
                    }
                    .frame(width: 60, height: 4)
                }
                
                Text("\(Int(percentage))%")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .glassText()
                    .frame(width: 35, alignment: .trailing)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private var diagonalColor: Color {
        diagonal == "Diagonal 1" ? 
            Color(red: 0.3, green: 0.7, blue: 0.9) : 
            Color(red: 0.9, green: 0.6, blue: 0.3)
    }
}

#Preview {
    VStack(spacing: 20) {
        ExpandableSummaryView(
            result: SummaryResult(
                diagonalAverages: ["Diagonal 1": 65, "Diagonal 2": 45],
                overallAverage: 55
            ),
            initiallyExpanded: false
        )
        
        ExpandableSummaryView(
            result: nil,
            initiallyExpanded: true
        )
    }
    .padding()
    .background(Color.black)
}
