//
//  MotionTestView.swift
//  TreeTop
//
//  Created by GitHub Copilot on 7/20/25.
//

import SwiftUI

struct MotionTestView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Motion Sensor Test")
                .font(.title)
                .padding()
            
            VStack {
                Text("Pitch: \(String(format: "%.2f", cameraManager.pitch * 180 / .pi))°")
                Text("Roll: \(String(format: "%.2f", cameraManager.roll * 180 / .pi))°")
                Text("Yaw: \(String(format: "%.2f", cameraManager.yaw * 180 / .pi))°")
            }
            .font(.system(.body, design: .monospaced))
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            VStack {
                HStack {
                    Circle()
                        .fill(cameraManager.isLeveledHorizontally ? Color.green : Color.red)
                        .frame(width: 20, height: 20)
                    Text("Leveled Horizontally")
                }
            }
            
            if cameraManager.isAutoCapturing {
                Text("Auto-capturing in \(cameraManager.countdownValue)...")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            BubbleLevelView(
                pitch: cameraManager.pitch,
                roll: cameraManager.roll,
                isLeveled: cameraManager.isLeveledHorizontally
            )
            .padding()
            
            Spacer()
        }
        .onAppear {
            // Just start motion tracking, not the camera
            cameraManager.setupMotionTracking()
        }
        .onDisappear {
            cameraManager.stopMotionTracking()
        }
    }
}

#Preview {
    MotionTestView()
}
