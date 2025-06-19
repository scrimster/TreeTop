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
    
    var body: some View {
        //creates a vertical stack layout
        VStack {
            CameraPreview(session: cameraManager.captureSession) //puts the live camera feed on the screen
                .ignoresSafeArea()
                .frame(height: 400)
            
            //below it creates the button: what it does, and what it looks like within the two sets of {}
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
            
            //checks if the image has been taken and stores it into the 'Image' variable
            if let image = cameraManager.capturedImage {
                Image(uiImage: image) //the bridge between UIKit-style to SwiftUI
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
            }
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
    LiveCameraView()
}
