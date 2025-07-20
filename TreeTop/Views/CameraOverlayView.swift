//
//  CameraOverlayView.swift
//  TreeTop
//
//  Created by GitHub Copilot on 7/20/25.
//

import SwiftUI
import CoreMotion

struct CameraOverlayView: View {
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        ZStack {
            // Only show overlay elements when auto-capture is enabled
            if cameraManager.autoCaptureEnabled {
                // Compass ticks around the edge
                CompassTicksView(yaw: cameraManager.yaw)
                
                // Central bubble level
                BubbleLevelView(
                    pitch: cameraManager.pitch,
                    roll: cameraManager.roll,
                    isLeveled: cameraManager.isLeveledHorizontally
                )
                .opacity(cameraManager.isReady ? 1.0 : 0.5) // Dim when not ready
                
                // Status indicators
                VStack {
                    // Level status at top of screen, below the mode toggle
                    HStack {
                        // Level status
                        HStack {
                            Image(systemName: cameraManager.isLeveledHorizontally ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(cameraManager.isLeveledHorizontally ? .green : .red)
                            Text("Level")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .opacity(cameraManager.isReady ? 1.0 : 0.5) // Dim when not ready
                        
                        Spacer()
                        
                        // Ready status
                        if cameraManager.autoCaptureEnabled {
                            HStack {
                                Image(systemName: cameraManager.isReady ? "checkmark.circle.fill" : "pause.circle.fill")
                                    .foregroundColor(cameraManager.isReady ? .green : .orange)
                                Text(cameraManager.isReady ? "Ready" : "Paused")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 80) // Position below the toggle button
                    
                    Spacer()
                    
                    // Countdown display
                    if cameraManager.isAutoCapturing {
                        Text("\(cameraManager.countdownValue)")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 5)
                            .scaleEffect(cameraManager.countdownValue > 0 ? 1.2 : 1.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: cameraManager.countdownValue)
                            .padding(.bottom, 100)
                    }
                }
            }
            
            // Instructions overlay
            if cameraManager.showInstructions {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            Text("Auto-Capture Enabled")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Hold phone level and steady")
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Text("Point towards the tree canopy")
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Text("Camera will auto-capture when aligned")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .transition(.opacity)
            }
        }
    }
}

struct BubbleLevelView: View {
    let pitch: Double
    let roll: Double
    let isLeveled: Bool
    
    private let bubbleSize: CGFloat = 20
    private let levelSize: CGFloat = 120
    
    var body: some View {
        ZStack {
            // Outer circle (level frame)
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: levelSize, height: levelSize)
                .overlay(
                    // Crosshairs
                    Group {
                        Rectangle()
                            .frame(width: 2, height: levelSize)
                            .foregroundColor(.white.opacity(0.5))
                        Rectangle()
                            .frame(width: levelSize, height: 2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                )
            
            // Bubble (indicates tilt)
            Circle()
                .fill(bubbleColor)
                .frame(width: bubbleSize, height: bubbleSize)
                .offset(bubbleOffset)
                .animation(.easeInOut(duration: 0.1), value: bubbleOffset)
            
            // Center target
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 12, height: 12)
        }
        .shadow(color: .black.opacity(0.5), radius: 5)
    }
    
    private var bubbleOffset: CGSize {
        let maxOffset = (levelSize - bubbleSize) / 2
        let x = min(max(roll * 200, -maxOffset), maxOffset) // Scale roll for visual effect
        let y = min(max(-pitch * 100, -maxOffset), maxOffset) // Negative pitch for intuitive movement
        return CGSize(width: x, height: y)
    }
    
    private var bubbleColor: Color {
        if isLeveled {
            return .green
        } else {
            return .red
        }
    }
}

struct CompassTicksView: View {
    let yaw: Double
    
    var body: some View {
        ZStack {
            ForEach(0..<36) { index in
                let angle = Double(index) * 10 // Every 10 degrees
                let isCardinal = index % 9 == 0 // Major ticks every 90 degrees
                let isMajor = index % 3 == 0 // Medium ticks every 30 degrees
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: isCardinal ? 30 : (isMajor ? 20 : 15))
                    .offset(y: -UIScreen.main.bounds.width / 2 + 50)
                    .rotationEffect(.degrees(angle - yaw * 180 / .pi))
                
                if isCardinal {
                    Text(cardinalText(for: index))
                        .foregroundColor(.white)
                        .font(.caption)
                        .fontWeight(.bold)
                        .offset(y: -UIScreen.main.bounds.width / 2 + 80)
                        .rotationEffect(.degrees(angle - yaw * 180 / .pi))
                }
            }
        }
    }
    
    private func cardinalText(for index: Int) -> String {
        switch index {
        case 0: return "N"
        case 9: return "E"
        case 18: return "S"
        case 27: return "W"
        default: return ""
        }
    }
}

#Preview {
    ZStack {
        Color.black
        CameraOverlayView(cameraManager: CameraManager())
    }
}
