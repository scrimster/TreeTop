//
//  LiveCameraView.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/18/25.
//

import SwiftUI
import AVFoundation

struct LiveCameraView: View {
    //this creates an object where it holds the logic of the camera function in CameraManager(). It monitors it for any change.
    @StateObject var cameraManager = CameraManager()
    //this is will keep track if the picture was taken or not
    @State var isPhotoTaken = false
    @State var showSaveConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    var project: Project
    @Binding var shouldGoToExistingProjects: Bool
    
    var body: some View {
        //creates a vertical stack layout
        VStack {
            //this block switches between the full-screen captured picture and the live camera preview
            if isPhotoTaken, let image = cameraManager.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else if cameraManager.isSessionRunning {
                CameraPreview(session: cameraManager.captureSession)
                    .ignoresSafeArea()
                
                Button(action: {
                    cameraManager.capturePhoto()
                }) {
                    Text("Take Photo")
                        .font(.title2)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
            else {
                ProgressView("Loading Camera...")
                    .foregroundColor(.white)
            }
            //below it creates the button: what it does, and what it looks like within the two sets of {}
            if isPhotoTaken {
                HStack {
                    Button(action: {
                        cameraManager.capturedImage = nil
                        isPhotoTaken = false
                    }) {
                        Text("Retake")
                            .font(.title2)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }
                    //once you hit save, the captured image should save to the newly created project
                    Button(action: {
                        if let image = cameraManager.capturedImage {
                            let success = ProjectManager.shared.saveImage(image, to: project)
                            if success {
                                showSaveConfirmation = true
                                print("Photo saved to project folder.")
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    shouldGoToExistingProjects = true
                                    dismiss()
                                }
                            } else {
                                print("Failed to save photo")
                            }
                        }
                    }) {
                        Text("Save")
                            .font(.title2)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .onChange(of: cameraManager.capturedImage) { //watch anytime this block of code changes
            if cameraManager.capturedImage != nil { //checks if the new photo was taken, if yes then it's bool changes
                isPhotoTaken = true
            }
        }
        
        .alert(isPresented: $showSaveConfirmation) {
            Alert(
                title: Text("Saved"),
                message: Text("Photo saved to project folder.")
            )
        }
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

#Preview {
    LiveCameraView(
        project: Project(name: "Preview Project", date: Date(), folderName: "PreviewFolder"),
        shouldGoToExistingProjects: .constant(false)
    )
}
