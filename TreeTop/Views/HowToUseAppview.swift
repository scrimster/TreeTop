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
            AnimatedForestBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text("How to Use TreeTop")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    StepView(stepNumber: 1,
                             instruction: "Tap 'Start Project' to begin collecting canopy data.",
                             gifName: "tree1")

                    StepView(stepNumber: 2,
                             instruction: "Hold your phone horizontally and use the bubble level to face straight up (zenith).",
                             gifName: "tree2")

                    StepView(stepNumber: 3,
                             instruction: "Walk two steps and take a canopy photo facing upward.",
                             gifName: "tree3")

                    StepView(stepNumber: 4,
                             instruction: "TreeTop stores metadata (GPS, date, time) and saves each image for analysis.",
                             gifName: "tree4")

                    StepView(stepNumber: 5,
                             instruction: "Repeat steps along two diagonal paths to collect balanced data.",
                             gifName: "tree5")

                    StepView(stepNumber: 6,
                             instruction: "Tap 'Save' to end the photo session. Your photos will be saved and organized by diagonal path.",
                             gifName: "tree6")

                    StepView(stepNumber: 7,
                             instruction: "Tap 'Summary' to analyze your photos. TreeTop converts each saved image to black & white, calculates the % black pixels (canopy cover) for each diagonal folder, and averages the results.",
                             gifName: "tree7")

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct StepView: View {
    let stepNumber: Int
    let instruction: String
    let gifName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Step \(stepNumber)")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            Text(instruction)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .background(.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(radius: 5)

                Image(gifName) // Replace with actual GIF later
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(20)
                    .padding()
            }
            .frame(height: 200)
        }
    }
}
