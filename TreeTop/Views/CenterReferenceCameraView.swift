import SwiftUI
import AVFoundation
import CoreLocation

struct CenterReferenceCameraView: View {
    @StateObject var cameraManager = CameraManager()
    @StateObject var locationManager = LocationManager()
    @State var capturedImage: UIImage?
    @State var showSaveConfirmation = false
    @Environment(\.dismiss) var dismiss
    @State var isPreviewingPhoto = false
    
    let project: Project
    
    var body: some View {
         VStack {
            //photo preview UI
            if isPreviewingPhoto, let image = capturedImage {
                VStack {
                    if let croppedImage = image.centerSquareCrop() {
                        Image(uiImage: croppedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(10)
                            .padding()
                    }
                    
                    HStack(spacing: 20) {
                        Button("Retake") {
                            isPreviewingPhoto = false
                            capturedImage = nil
                            cameraManager.capturedImage = []
                        }
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("Set as Center Reference") {
                            saveCenterReference()
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // Location information
                    if let location = locationManager.currentLocation {
                        VStack(spacing: 4) {
                            Text("Location Data Available")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(.green)
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Lat: \(String(format: "%.6f", location.coordinate.latitude))")
                                    Text("Lon: \(String(format: "%.6f", location.coordinate.longitude))")
                                }
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                
                                if location.altitude > 0 {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Alt: \(String(format: "%.1f", location.altitude))m")
                                        Text("Acc: ±\(String(format: "%.1f", location.horizontalAccuracy))m")
                                    }
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    } else {
                        Text("⚠️ No location data available")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.orange)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                    }
                }
            } else {
                //live camera view
                CameraPreview(session: cameraManager.captureSession)
                    .ignoresSafeArea(.all, edges: .all)
                    .overlay(
                        VStack {
                            // Location status indicator
                            VStack(spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: locationManager.currentLocation != nil ? "location.fill" : "location.slash")
                                        .foregroundColor(locationManager.currentLocation != nil ? .green : .red)
                                    
                                    Text(locationManager.currentLocation != nil ? "Location Available" : "Getting Location...")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                            }
                            .padding(.top, 50)
                            
                            Spacer()
                            
                            if project.hasCenterReference {
                                Text("Replace Center Reference Photo")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.8))
                                    .cornerRadius(10)
                                    .padding(.bottom, 10)
                            } else {
                                Text("Capture Center Reference Photo")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.orange.opacity(0.8))
                                    .cornerRadius(10)
                                    .padding(.bottom, 10)
                            }
                            
                            Button(action: {
                                print("🔍 CenterReference: Capture button tapped")
                                print("🔍 CenterReference: Session running? \(cameraManager.captureSession.isRunning)")
                                cameraManager.capturePhoto()
                            }) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.orange, lineWidth: 3)
                                            .frame(width: 60, height: 60)
                                    )
                            }
                            .padding(.bottom, 50)
                        }
                    )
            }
        }
        .onReceive(cameraManager.$capturedImage) { images in
            print("🔍 CenterReference: Received captured images: \(images.count)")
            if let latestImage = images.last {
                print("🔍 CenterReference: Setting captured image and showing preview")
                capturedImage = latestImage
                isPreviewingPhoto = true
                cameraManager.capturedImage = []
            }
        }
        .alert(isPresented: $showSaveConfirmation) {
            Alert(
                title: Text("Center Reference Set"),
                message: Text("Photo and location data saved to your project."),
                dismissButton: .default(Text("OK")) {
                    dismiss()
                }
            )
        }
        .onAppear {
            print("🔍 CenterReference: View appeared, initializing camera")
            cameraManager.initializeCamera()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private func saveCenterReference() {
        guard let image = capturedImage else { return }
        
        let success = ProjectManager.shared?.saveCenterReferencePhoto(image, to: project, location: locationManager.currentLocation) ?? false
        
        if success {
            showSaveConfirmation = true
        } else {
            // Handle error case
            print("Failed to save center reference photo")
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // nothing to update
    }
}

#Preview {
    // This would need a mock project for preview
    Text("Center Reference Camera Preview")
}
