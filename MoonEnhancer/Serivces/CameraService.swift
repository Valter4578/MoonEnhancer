//
//  CameraService.swift
//  MoonEnhancer
//
//  Created by Максим Алексеев  on 12.11.2023.
//

import Foundation
import SwiftUI
import AVFoundation

struct Photo: Identifiable, Equatable {
    //    The ID of the captured photo
    var id: String
    //    Data representation of the captured photo
    var originalData: Data
    
    init(id: String = UUID().uuidString, originalData: Data) {
        self.id = id
        self.originalData = originalData
    }
}

public class CameraService {
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    // MARK: - Properties
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var shouldShowAlertView = false
    @Published var shouldShowSpinner = false
    @Published var willCapturePhoto = false
    @Published var isCameraButtonDisabled = true
    @Published var isCameraUnavailable = true
    @Published var photo: Photo?
    
    // Session Management Properties
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private var isConfigured = false
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    // Device Configuration Properties
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera], mediaType: .video, position: .unspecified)
    
    // Capturing Photos Properties
    private let photoOutput = AVCapturePhotoOutput()
    
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    
    // MARK: - Functions
    func setUpCaptureSession() async {
        guard await isAuthorized else { return }
        // Set up the capture session.
        
        session.beginConfiguration()
        
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            }
            //            else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            //                defaultVideoDevice = frontCameraDevice
            //            }
            //
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                session.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
            } else {
                print("Couldn't add video device input to the session.")
                session.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            session.commitConfiguration()
            return
        }
        
        // Add the photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.maxPhotoQualityPrioritization = .quality
            
        } else {
            print("Could not add photo output to the session")
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
        isConfigured = true
        
        startSession()
    }
    
    func startSession() {
        sessionQueue.async {
            if !self.isSessionRunning && self.isConfigured {
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                
                if self.session.isRunning {
                    DispatchQueue.main.async {
                        self.isCameraButtonDisabled = false
                        self.isCameraUnavailable = false
                    }
                }
            }
        }
    }
    
    func capturePhoto() {
        self.isCameraButtonDisabled = true
        
        sessionQueue.async {
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = .portrait
            }
            
            var photoSettings = AVCapturePhotoSettings()
            
            // Capture HEIF photos when supported. Enable according to user settings and high-resolution photos.
            if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            // Sets the flash option for this capture.
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = self.flashMode
            }
                        
            // Sets the preview thumbnail pixel format
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            photoSettings.photoQualityPrioritization = .quality
            
            let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, willCapturePhotoAnimation: {
                // Tells the UI to flash the screen to signal that SwiftCamera took a photo.
                DispatchQueue.main.async {
                    self.willCapturePhoto.toggle()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.willCapturePhoto.toggle()
                }
                
            }, completionHandler: { (photoCaptureProcessor) in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                if let data = photoCaptureProcessor.photoData {
                    self.photo = Photo(originalData: data)
                    print("passing photo")
                } else {
                    print("No photo data")
                }
                
                self.isCameraButtonDisabled = false
                
                self.sessionQueue.async {
                    self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                }
            }, photoProcessingHandler: { animate in
                // Animates a spinner while photo is processing
                if animate {
                    self.shouldShowSpinner = true
                } else {
                    self.shouldShowSpinner = false
                }
            })
            
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
}

