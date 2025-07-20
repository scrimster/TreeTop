//
//  LiveCameraView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/18/25.
//

import SwiftUI
import AVFoundation


//this creates an object where it holds the logic of the camera function in CameraManager(). It monitors it for any change.
struct LiveCameraView: View {
    @StateObject var cameraManager = CameraManager()
    @State var capturedImages: [UIImage] = []
    @State var showSaveConfirmation = false
    @Environment(\.dismiss) var dismiss
    @State var isPreviewingPhoto = false
    @State var showConfirmationDialog = false
    
    var saveToURL: URL
    
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
                            Image(systemName: cameraManager.isReady ? "checkmark.circle.fill" : "pause.circle.fill")
                            Text(cameraManager.isReady ? "Ready" : "Not Ready")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(cameraManager.isReady ? Color.green.opacity(0.8) : Color.orange.opacity(0.8))
                        .cornerRadius(25)
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
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                
                do {
                    try FileManager.default.createDirectory(at: saveToURL, withIntermediateDirectories: true)
                    
                    let baseTimestamp = dateFormatter.string(from: Date())
                    
                    for (index, image) in capturedImages.enumerated() {
                        let fileName = "image_\(baseTimestamp)_\(String(format: "%02d", index)).jpg"
                        let fileURL = saveToURL.appendingPathComponent(fileName)
                        
                        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                            print("failed to convert image to JPEG data")
                            continue
                        }
                        
                        try imageData.write(to: fileURL)
                        print("saved: \(fileURL.lastPathComponent)")
                    }
                    
                    // Immediately return to project page
                    dismiss()
                } catch {
                    print("failed to save images: \(error)")
                }
            }
            Button("Cancel", role: .cancel) {}
        }
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

        return LiveCameraView(saveToURL: exampleURL)
    }
