//
//  AboutTreeTopView.swift
//  TreeTop
//
//  Created by Lesly Reinoso on 7/13/25.

import SwiftUI

struct AboutTreeTopView: View {
    var body: some View {
        ZStack {
            AnimatedForestBackground()
                .ignoresSafeArea()
                .allowsHitTesting(false) // Prevent background from intercepting touches

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("About TreeTop")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)

                    // Subtitle
                    Text("A mobile canopy tool designed for GLOBE's global science community")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.95))

                    Divider()
                        .background(.white.opacity(0.4))

                    // App Description
                    Text("""
TreeTop is a lightweight, mobile canopy cover measurement app designed for the International GLOBE Program. With a worldwide citizen science initiative active in over 120 countries.

This app allows users to calculate % Canopy Cover using their iPhone’s camera, accelerometer, gyroscope, and GPS. It replaces expensive ($120+) or homemade tools by letting users capture high-contrast canopy images, convert them to black & white, and compute canopy coverage using pixel analysis, while in the field.

TreeTop collects location, date, and time metadata with each image and provides real-time guidance to help users aim directly overhead using a digital bubble level.
""")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.95))
                        .lineSpacing(6)

                    // Features List
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Features")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        FeatureRow(icon: "camera.fill", text: "Capture stabilized canopy photos")
                        FeatureRow(icon: "location.fill", text: "GPS-tagged with date and time")
                        FeatureRow(icon: "gyroscope", text: "Real-time phone angle guidance")
                        FeatureRow(icon: "doc.text.magnifyingglass", text: "Auto-generate canopy % and summary")
                        FeatureRow(icon: "externaldrive.fill.badge.checkmark", text: "Save image and data locally")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    // Capstone Note
                    Label(
                        "TreeTop was developed as a 2025 capstone project by three students at Southern Connecticut State University.",
                        systemImage: "graduationcap.fill"
                    )
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top)

                    // Credits
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Credits", systemImage: "person.3.fill")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Client: Dr. Scott M. Graves")
                        Text("Student Developers:")
                        Text("• Ashley Sanchez")
                        Text("• Sebastian Scrimenti")
                        Text("• Lesly Reinoso")
                    }
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)

                    // GLOBE Link Button
                    HStack {
                        Spacer()
                        Link(destination: URL(string: "https://www.globe.gov")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                Text("Visit GLOBE")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(radius: 3)
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .opacity(0.65)
                )
                .padding()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.08, green: 0.15, blue: 0.4, alpha: 1.0) // matches animated background

            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
                .foregroundColor(.white.opacity(0.95))
        }
        .font(.subheadline)
    }
}
