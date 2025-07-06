//
//  CameraManager.swift
//  TreeTop
//
//  Created by Ashley Sanchez on 6/17/25.
//  Taking a picture is complicated, did not test. Will probably need to create a SwiftUI file to preview.

import Foundation
import AVFoundation
import UIKit
import SwiftUI

class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate{
    
    @Published var capturedImage: UIImage? //this will be able to access the image from outside code
    @Published var isSessionRunning = false
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureDevice: AVCaptureDevice? //defining its type but also saying it might not exist depending on if the camera works
    
    override init() {
        super.init()
        configureSession() //this section will initialize the camera session settings.
    }
    
    func configureSession() {
        //beginning the configuration and using the photo preset given by Apple
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        //setting up the capture device for front-facing camera
        captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        
        //going to check if the camera works in captureDevice
        if let device = captureDevice {
            do {
                let input = try AVCaptureDeviceInput(device: device) //defining the device input by passing the device into the AVCaptureDeviceInput function
                
                //this is establishing the input and output of the camera for this session
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
                
                //setting up the preview session of the live video image before capturing the still photo
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = .resizeAspectFill
                
                //after we're done making changes, we are committing and starting the session
                captureSession.commitConfiguration()
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                    
                    DispatchQueue.main.async {
                        self.isSessionRunning = true
                    }
                }
                
            } catch {
                print("failed to set-up camera input: ", error)
            }
        } else {
            print("No camera found.")
        }
    }
    
    //this function is going to actually capture the photo now that the session is configured. We need to set-up the photo settings before capturing the still photo
    func capturePhoto() {
        let settings = AVCapturePhotoSettings() //leaving settings as is, maybe need to change in the future, depending on what the AI needs. Image stabilization is automatically turned on for iOS 13 and later.
        photoOutput.capturePhoto(with: settings, delegate: self) //delegate means you're passing an object to track the progress of and handle the results from that photo capture
    }
    
    //creating the photoOutput function so that it can be called automatically after the camera finishes taking a picture.
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        } else {
            print("Failed to capture photo:", error?.localizedDescription ?? "Unknown error")
        }
    }
    
}
