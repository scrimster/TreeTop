//
//  LiveCameraView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/18/25.
//

import SwiftUI
import AVFoundation
import CoreLocation


//this creates an object where it holds the logic of the camera function in CameraManager(). It monitors it for any change.
struct LiveCameraView: View {
    @StateObject var cameraManager = CameraManager()
    @State var capturedImages: [UIImage] = []
    @State var showSaveConfirmation = false
    @Environment(\.dismiss) var dismiss
    @State var isPreviewingPhoto = false
    @State var showConfirmationDialog = false
    @State var showBackWarning = false
    
    var saveToURL: URL
    var project: Project
    var diagonalName: String
    
    var body: some View {
         VStack {
            //photo preview UI
            if isPreviewingPhoto, let image = capturedImages.last {
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .transition(.opacity)
                    
                    HStack {
                        Button(action: {
                            isPreviewingPhoto = false
                        }) {
                            Text("Save")
                                .font(.title2)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        
                        Button(action: {
                            capturedImages.removeLast()
                            isPreviewingPhoto = false
                        }) {
                            Text("Retake")
                                .font(.title2)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                }
            } //live camera UI
            else if cameraManager.isSessionRunning {
                ZStack {
                    CameraPreview(session: cameraManager.captureSession)
                        .ignoresSafeArea()
                    
                    // Overlay with bubble level and compass (only when auto-capture enabled)
                    CameraOverlayView(cameraManager: cameraManager)
                        .allowsHitTesting(false)
                    
                    // UI Controls
                    VStack {
                        // Auto-capture toggle button (top)
                        HStack {
                            Button(action: {
                                cameraManager.toggleAutoCapture()
                            }) {
                                HStack {
                                    Image(systemName: cameraManager.autoCaptureEnabled ? "viewfinder.circle.fill" : "viewfinder.circle")
                                    Text(cameraManager.autoCaptureEnabled ? "Auto" : "Manual")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(cameraManager.autoCaptureEnabled ? Color.green.opacity(0.8) : Color.black.opacity(0.6))
                                .cornerRadius(20)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // Manual capture button (bottom center) - only show when not in auto mode
                        if !cameraManager.autoCaptureEnabled && !cameraManager.isAutoCapturing {
                            Button(action: {
                                cameraManager.capturePhoto()
                            }) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black, lineWidth: 2)
                                            .frame(width: 60, height: 60)
                                    )
                            }
                            .padding(.bottom, 50)
                        } else {
                            // Spacer to maintain layout when button is hidden
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 120)
                        }
                    }
                }
                
                // Ready button - always show when in auto mode
                if cameraManager.autoCaptureEnabled {
                    Button(action: {
                        cameraManager.toggleReady()
                    }) {
                        HStack {
                            Image(systemName: cameraManager.isReady ? "checkmark.circle.fill" : "hand.tap.fill")
                            Text(cameraManager.isReady ? "Ready - Tap to Pause" : "Tap to Ready")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(cameraManager.isReady ? Color.green.opacity(0.9) : Color.orange.opacity(0.9))
                        .cornerRadius(30)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .scaleEffect(cameraManager.isReady ? 1.0 : 1.05)
                        .animation(.easeInOut(duration: 0.2), value: cameraManager.isReady)
                    }
                    .padding(.top, 8)
                }
                
                //save & thumbnail gallery
                if !capturedImages.isEmpty {
                    Button(action: {
                        showConfirmationDialog = true
                    }) {
                        Text("Save All")
                            .font(.title2)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .padding(.top)
                    
                    if !capturedImages.isEmpty {
                        Text("\(capturedImages.count) photo\(capturedImages.count == 1 ? "" : "s") captured")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 2)
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack(spacing: 12) {
                                ForEach(capturedImages.indices, id: \.self) {
                                    index in
                                    Image(uiImage: capturedImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                                        .onTapGesture {
                                            isPreviewingPhoto = true
                                            let tappedImage = capturedImages[index]
                                            capturedImages.remove(at: index)
                                            capturedImages.append(tappedImage)
                                        }
                                        .id(index)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: capturedImages.count) { oldCount, newCount in
                            withAnimation {
                                proxy.scrollTo(capturedImages.indices.last, anchor: .trailing)
                            }
                        }
                    }
                }
                } else {
                    ProgressView("Loading Camera...")
                        .foregroundColor(.white)
                }
        }
        .onAppear {
            // Start initialization immediately when view appears
            if !cameraManager.isSessionRunning {
                cameraManager.initializeCamera()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) {
            capturedImages.append(contentsOf: cameraManager.capturedImage)
            isPreviewingPhoto = true
            cameraManager.capturedImage = []
        }
        .alert(isPresented: $showSaveConfirmation) {
            Alert(
                title: Text("Saved"),
                message: Text("Photo saved to project folder.")
            )
        }
        .confirmationDialog("Save all photos?", isPresented: $showConfirmationDialog, titleVisibility: .visible) {
            Button("Confirm Save", role: .destructive) {
                saveCapturedImages()
            }
            Button("Cancel", role: .cancel) {}
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    if !capturedImages.isEmpty {
                        showBackWarning = true
                    } else {
                        dismiss()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Unsaved Progress", isPresented: $showBackWarning) {
            Button("Continue Capturing", role: .cancel) { }
            Button("Discard Photos", role: .destructive) {
                capturedImages.removeAll()
                dismiss()
            }
        } message: {
            Text("You have \(capturedImages.count) unsaved photos. Are you sure you want to discard them?")
        }
    }
    
    private func saveCapturedImages() {
        print("📸 Total captured images before saving", capturedImages.count)
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            var savedImageURLs: [URL] = []

            for (index, image) in capturedImages.enumerated() {
                let filename = "image_\(dateFormatter.string(from: Date()))_\(String(format: "%02d", index)).jpg"
                let fileURL = saveToURL.appendingPathComponent(filename)

                if let data = image.jpegData(compressionQuality: 1.0) {
                    try data.write(to: fileURL)
                    savedImageURLs.append(fileURL)
                    print("📸 Saved: \(fileURL.lastPathComponent)")

                    if index == 0 {
                        print("✅ This is the FIRST image: \(fileURL.lastPathComponent)")
                    }
                    if index == capturedImages.count - 1 {
                        print("✅ This is the LAST image: \(fileURL.lastPathComponent)")
                    }
                }
            }

                print("📁 Total savedImageURLs to be processed: \(savedImageURLs.count)")
                savedImageURLs.forEach { url in
                    print("📂 Image file: \(url.lastPathComponent)")
                }

            // Post notification that this diagonal has new photos
            NotificationCenter.default.post(name: .diagonalPhotosSaved, object: nil, userInfo: ["diagonal": diagonalName])
            } catch {
            print("❌ Failed to save image: \(error)")
        }

        // Dismiss back to project page to avoid duplicate saves
        DispatchQueue.main.async {
            showConfirmationDialog = false
            capturedImages.removeAll()
            dismiss()
        }
    }
    
    func injectGPSMetadataToEndpoints(location: CLLocation, savedImageURLs: [URL]) {
        for fileURL in savedImageURLs {
            guard let imageData = try? Data(contentsOf: fileURL),
                  let source = CGImageSourceCreateWithData(imageData as CFData, nil),
                  let uti = CGImageSourceGetType(source),
                  let destination = CGImageDestinationCreateWithURL(fileURL as CFURL, uti, 1, nil) else {
                continue
            }

            let gpsMetadata = location.toGPSMetadata() as CFDictionary
            CGImageDestinationAddImageFromSource(destination, source, 0, gpsMetadata)
            CGImageDestinationFinalize(destination)
        }

        print("✅ GPS metadata injected with fresh location request.")
    }

    
    struct CameraPreview: UIViewRepresentable {
        let session: AVCaptureSession //creates a constant and defines the datatype
        
        //this function allows the UIKit to be displayed in SwiftUI, this is required acts like a bridge
        func makeUIView(context: Context) -> UIView {
            let view = UIView() //blank container to attach the camera preview to when ready
            
            //defining the camera preview we're going to see, the preview takes up the full screen, then attach the preview to the blank view container as a sublayer, then returns the filled in view container.
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = UIScreen.main.bounds
            view.layer.addSublayer(previewLayer) //
            
            return view
        }
        
        func updateUIView(_ uiView: UIView, context: Context) {
            //nothing to update
        }
    }
}

#Preview {
    let exampleURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        .appendingPathComponent("PreviewFolder")

    let dummyProject = Project(
        name: "Preview",
        date: Date(),
        folderName: "PreviewFolder",
        location: LocationModel()
    )

    LiveCameraView(
        saveToURL: exampleURL,
        project: dummyProject,
        diagonalName: "Diagonal 1"
    )
}


//#Preview {
//        let exampleURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//            .appendingPathComponent("PreviewFolder")
//
//        return LiveCameraView(saveToURL: exampleURL)
//    }
