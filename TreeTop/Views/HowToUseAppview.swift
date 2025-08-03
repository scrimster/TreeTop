//
//  HowToUseAppview.swift
//  TreeTop
//
//  Created by Lesly Reinoso on 7/13/25.
//

import SwiftUI

struct HowToUseAppView: View {
    var body: some View {
        ZStack {
            PerformanceOptimizedBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Use TreeTop")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    FrostedStepCard(stepNumber: 1, instruction: "Tap 'New Project' and enter unique project name to begin collecting canopy data.")
                    FrostedStepCard(stepNumber: 2, instruction: "Select your project and tap on 'Take Photo' to pick which diagonal to start with.")
                    FrostedStepCard(stepNumber: 3, instruction: "Hold your phone horizontal and use the bubble level to face straight up if autocapture is selected. Otherwise take photo manually.")
                    FrostedStepCard(stepNumber: 4, instruction: "For every two steps taken on the diagonal take a canopy photo facing upward.")
                    FrostedStepCard(stepNumber: 5, instruction: "Tap 'Save' after every photo, and once all photos have been taken on a diagonal, tap 'Save All.'")
                    FrostedStepCard(stepNumber: 6, instruction: "Once all photos are saved for the first diagonal path, tap 'Take Photo' to begin the second diagonal path.")
                    FrostedStepCard(stepNumber: 7, instruction: "After completing the second diagonal path, tap 'Run Canopy Analysis' to analyze your photos.")
                    FrostedStepCard(stepNumber: 8, instruction: "TreeTop converts each saved image to black & white, calculates the % black pixels (canopy cover) for each diagonal folder, and averages the results.")
                    FrostedStepCard(stepNumber: 9, instruction: "TreeTop stores metadata (GPS, date, time) and saves each image for analysis.")

                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle("How to Use")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.08, green: 0.15, blue: 0.4, alpha: 1.0) // matches animated background top
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct FrostedStepCard: View {
    let stepNumber: Int
    let instruction: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(stepNumber)")
                .font(.headline)
                .foregroundColor(.white)

            Text(instruction)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(radius: 5)
    }
}
