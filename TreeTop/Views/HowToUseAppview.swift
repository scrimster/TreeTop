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
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Use TreeTop")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("""
1. Tap **New Project** from the main menu.
2. Follow the instructions to frame your canopy image.
3. Use the phone's tilt guidance to aim straight up.
4. Tap **Capture** to take the photo.
5. Review the image. Retake if needed.
6. The app saves location, time, and image.
7. View saved projects under **Existing Projects**.

For best results, stand in the center of the area you're measuring and avoid direct sunlight in the frame.
""")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.body)
                }
                .padding()
            }
        }
        .navigationTitle("How to Use")
        .navigationBarTitleDisplayMode(.inline)
    }
}
