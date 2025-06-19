//
//  CanopyScannerView.swift
//  TreeTop
//
//  Created by Sebastian Scrimenti on 6/19/25.
//


import SwiftUI

struct CanopyScannerView: View {
    @State private var pickedImage: UIImage?
    @State private var canopyPct: Double?
    @State private var showPicker = false
    @State private var errorMessage: String?

    private let analyzer = CanopyCoverAnalyzer()!

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let uiImage = pickedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                } else {
                    Color.secondary.opacity(0.1)
                        .frame(height: 300)
                        .overlay(Text("No Image Selected"))
                }

                if let pct = canopyPct {
                    Text("Canopy Cover: \(pct, specifier: "%.1f")%")
                        .font(.title2)
                }

                if let error = errorMessage {
                    Text("❌ \(error)")
                        .foregroundColor(.red)
                }

                HStack {
                    Button("Pick Photo") {
                        showPicker = true
                    }
                    .buttonStyle(.borderedProminent)

                    if pickedImage != nil {
                        Button("Analyze") {
                            analyzeImage()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Canopy Scanner")
            .sheet(isPresented: $showPicker) {
                ImagePicker(image: $pickedImage)
            }
        }
    }

    private func analyzeImage() {
        guard let image = pickedImage else { return }
        errorMessage = nil
        Task {
            do {
                let pct = try await analyzer.canopyCoverPercentage(for: image)
                canopyPct = pct
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct CanopyScannerView_Previews: PreviewProvider {
    static var previews: some View {
        CanopyScannerView()
    }
}
