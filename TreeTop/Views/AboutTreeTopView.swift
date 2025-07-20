//
//  AboutTreeTopView.swift
//  TreeTop
//
//  Created by Lesly Reinoso on 7/13/25.
//

import SwiftUI

struct AboutTreeTopView: View {
    var body: some View {
        ZStack {
            AnimatedForestBackground()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("About TreeTop")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("""
TreeTop is a field-ready iOS app designed to help users measure canopy cover using their iPhone. It uses stabilized images and onboard sensors like GPS, accelerometer, and gyroscope to capture accurate environmental data in real time.

With TreeTop, you can:
• Take canopy photos
• Automatically store location and time
• Preview and retake images
• Get guidance on how to angle your phone correctly

TreeTop is built for researchers, ecologists, and everyday nature lovers who want a reliable way to measure tree density and canopy coverage.
""")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.body)
                }
                .padding()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
