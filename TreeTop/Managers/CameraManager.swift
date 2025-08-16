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
import CoreMotion

class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate{
    
    @Published var capturedImage: [UIImage] = [] //this will be able to access the image from outside code
    @Published var isSessionRunning = false
    @Published var isLeveledHorizontally = false
    @Published var isAutoCapturing = false
    @Published var countdownValue: Int = 0
    @Published var pitch: Double = 0.0 // Forward/backward tilt
    @Published var roll: Double = 0.0  // Left/right tilt
    @Published var yaw: Double = 0.0   // Compass heading
    @Published var autoCaptureEnabled = false // Toggle for auto-capture mode
    @Published var showInstructions = false // Show orientation instructions
    @Published var isReady = false // Ready to capture when in auto mode
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureDevice: AVCaptureDevice? //defining its type but also saying it might not exist depending on if the camera works
    
    private let motionManager = CMMotionManager()
    private var countdownTimer: Timer?
    private let levelThreshold: Double = 0.15 // Radians (about 8.6 degrees) - more forgiving
    private var isInitializing = false // Prevent multiple initialization attempts
    
    override init() {
        super.init()
        // Pre-configure session to reduce startup time
        captureSession.sessionPreset = .photo
        setupMotionTracking()
    }
    
    deinit {
        stopMotionTracking()
    }
    
    func setupMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.1
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else {
                print("Motion update error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            self?.updateDeviceOrientation(motion: motion)
        }
    }
    
    func stopMotionTracking() {
        motionManager.stopDeviceMotionUpdates()
        countdownTimer?.invalidate()
    }
    
    private func updateDeviceOrientation(motion: CMDeviceMotion) {
        let attitude = motion.attitude
        
        // Convert to radians for calculations
        pitch = attitude.pitch
        roll = attitude.roll
        yaw = attitude.yaw
        
        // Only process auto-capture if enabled AND ready
        guard autoCaptureEnabled && isReady else {
            isLeveledHorizontally = false
            return
        }
        
        // Check if device is level horizontally (minimal roll AND pitch)
        let wasLeveled = isLeveledHorizontally
        isLeveledHorizontally = abs(roll) < levelThreshold && abs(pitch) < levelThreshold
        
        // Start countdown when device is level
        let shouldAutoCapture = isLeveledHorizontally
        
        if shouldAutoCapture && !isAutoCapturing && !wasLeveled {
            startAutoCapture()
        } else if !shouldAutoCapture && isAutoCapturing {
            cancelAutoCapture()
        }
    }
    
    func toggleAutoCapture() {
        autoCaptureEnabled.toggle()
        
        if autoCaptureEnabled {
            // Show instructions when enabling
            showInstructions = true
            isReady = false // Start in not ready state
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.showInstructions = false
            }
        } else {
            // Cancel any ongoing auto-capture and reset
            cancelAutoCapture()
            isLeveledHorizontally = false
            isReady = false
        }
    }
    
    func toggleReady() {
        isReady.toggle()
        
        if !isReady {
            // Cancel any ongoing auto-capture when not ready
            cancelAutoCapture()
            isLeveledHorizontally = false
        }
    }
    
    private func startAutoCapture() {
        isAutoCapturing = true
        countdownValue = 3
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.countdownValue > 0 {
                self.countdownValue -= 1
            } else {
                timer.invalidate()
                self.capturePhoto()
                self.isAutoCapturing = false
                self.countdownValue = 0
            }
        }
    }
    
    private func cancelAutoCapture() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isAutoCapturing = false
        countdownValue = 0
    }
    
    
    func initializeCamera() {
        // Prevent multiple initialization attempts
        guard !isInitializing && !isSessionRunning else { return }
        isInitializing = true
        
        // Check camera authorization first - but don't wait for it
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            // Setup immediately on background thread
            setupCameraSession()
        case .notDetermined:
            // Request permission but setup optimistically
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    // Permission granted, continue with already started setup
                    print("Camera permission granted")
                } else {
                    print("Camera permission denied")
                    DispatchQueue.main.async {
                        self?.isInitializing = false
                    }
                }
            }
            // Start setup immediately - will succeed if permission is granted
            setupCameraSession()
        case .denied, .restricted:
            print("Camera access denied")
            isInitializing = false
        @unknown default:
            print("Unknown camera authorization status")
            isInitializing = false
        }
    }
    
    private func setupCameraSession() {
        // Run on background thread for best performance
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Early exit if session is already configured
            if self.captureSession.isRunning {
                DispatchQueue.main.async {
                    self.isInitializing = false
                    self.isSessionRunning = true
                }
                return
            }
            
            //beginning the configuration - preset already set in init
            self.captureSession.beginConfiguration()
            
            //setting up the capture device for front camera (allows seeing screen while aligning)
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                print("No front camera found")
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    self.isInitializing = false
                }
                return
            }
            
            self.captureDevice = device
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                
                // Add input and output efficiently
                if self.captureSession.canAddInput(input) && self.captureSession.canAddOutput(self.photoOutput) {
                    self.captureSession.addInput(input)
                    self.captureSession.addOutput(self.photoOutput)
                } else {
                    print("Cannot add camera input/output")
                    self.captureSession.commitConfiguration()
                    DispatchQueue.main.async {
                        self.isInitializing = false
                    }
                    return
                }
                
                //after we're done making changes, we are committing and starting the session
                self.captureSession.commitConfiguration()
                
                // Start session immediately - no additional dispatch needed
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                    self.isInitializing = false
                }
                
            } catch {
                print("Failed to set-up camera input: ", error)
                self.captureSession.commitConfiguration()
                DispatchQueue.main.async {
                    self.isInitializing = false
                }
            }
        }
    }
    
            // Capture photo with configured session and photo settings
    func capturePhoto() {
        guard captureSession.isRunning else {
            print("Capture session not running")
            return
        }
        
        let settings = AVCapturePhotoSettings() //leaving settings as is, maybe need to change in the future, depending on what the AI needs. Image stabilization is automatically turned on for iOS 13 and later.
        
        photoOutput.capturePhoto(with: settings, delegate: self) //delegate means you're passing an object to track the progress of and handle the results from that photo capture
    }
    
    func stopSession() {
        stopMotionTracking()
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    //creating the photoOutput function so that it can be called automatically after the camera finishes taking a picture.
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.capturedImage.append(image)
                
                // Automatically set to not ready after taking a photo in auto mode
                if self.autoCaptureEnabled {
                    self.isReady = false
                }
            }
        } else {
            print("Failed to capture photo:", error?.localizedDescription ?? "Unknown error")
        }
    }
    
}
