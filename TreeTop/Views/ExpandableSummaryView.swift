//
//  ExpandableSummaryView.swift
//  TreeTop
//
//  Created by Assistant on 7/28/25.
//

import SwiftUI

struct ExpandableSummaryView: View {
    let result: SummaryResult
    @State private var isExpanded: Bool = false
    let initiallyExpanded: Bool
    
    init(result: SummaryResult, initiallyExpanded: Bool = false) {
        self.result = result
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
                        
                        Text("Overall Canopy Cover")
                            .font(.system(.caption, design: .rounded))
                            .glassTextSecondary(opacity: 0.7)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
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
                        
                        // Diagonal breakdown
                        VStack(spacing: 8) {
                            Text("Diagonal Breakdown")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .glassText()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(result.diagonalAverages.keys.sorted(), id: \.self) { key in
                                if let value = result.diagonalAverages[key] {
                                    DiagonalSummaryRow(
                                        diagonal: key,
                                        percentage: value
                                    )
                                }
                            }
                        }
                        
                        // Analysis timestamp
                        if initiallyExpanded {
                            VStack(spacing: 4) {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 12))
                                        .glassTextSecondary(opacity: 0.6)
                                    
                                    Text("Analysis completed \(formatTimestamp())")
                                        .font(.system(.caption2, design: .rounded))
                                        .glassTextSecondary(opacity: 0.6)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
                }
            }
            .padding(20)
        }
    }
    
    private func formatTimestamp() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: Date(), relativeTo: Date())
    }
}

struct DiagonalSummaryRow: View {
    let diagonal: String
    let percentage: Double
    
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
            result: SummaryResult(
                diagonalAverages: ["Diagonal 1": 80, "Diagonal 2": 70],
                overallAverage: 75
            ),
            initiallyExpanded: true
        )
    }
    .padding()
    .background(Color.black)
}
