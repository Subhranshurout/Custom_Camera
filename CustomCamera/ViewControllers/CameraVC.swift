//
//  ViewController.swift
//  CustomCamera
//
//  Created by Yudiz-subhranshu on 10/10/23.
//

import UIKit
import AVFoundation
import Photos

class CameraVC: UIViewController {
    // MARK: Outlets
    @IBOutlet var videoTimerImageView: UIImageView! {
        didSet {
            videoTimerImageView.isUserInteractionEnabled = true
            videoTimerImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showTimerActionSheet)))
        }
    }
    
    @IBOutlet var torchImageView: UIImageView! {
        didSet {
            torchImageView.isUserInteractionEnabled = true
            torchImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleTorch)))
        }
    }
    
    @IBOutlet var sutterButton: UIButton!
    
    @IBOutlet var togglePhotoVideo: UIImageView! {
        didSet {
            togglePhotoVideo.isUserInteractionEnabled = true
            togglePhotoVideo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(togglePhotoVideoMode)))
        }
    }
    
    @IBOutlet var preViewImageView: UIImageView! {
        didSet {
            preViewImageView.isUserInteractionEnabled = true
            preViewImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewImages)))
        }
    }
    
    @IBOutlet var toggleCameraImageView: UIImageView! {
        didSet {
            toggleCameraImageView.isUserInteractionEnabled = true
            toggleCameraImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleCameraType)))
        }
    }
    
    @IBOutlet var cameraView: UIView!
    
    @IBOutlet var torchImageViewLeftConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    var session: AVCaptureSession?
    /// for recording video
    var movieOutput = AVCaptureMovieFileOutput()
    /// camera output
    var output = AVCapturePhotoOutput()
    /// for camera view
    var previewLayer = AVCaptureVideoPreviewLayer()
    /// camera input
    var input : AVCaptureDeviceInput?
    /// for recording audio for video
    var audioInput : AVCaptureDeviceInput?
    /// manageing front and back caera
    var devicePosition: AVCaptureDevice.Position = .back
    var clickedImages = [UIImage]()
    var isCapturingPhoto = true
    var isRecordingVideo = false
    var timer: Timer?
    var timeInterVal : TimeInterval = TimeInterval(10.0)
    /// local identifier of the album
    var customAlbumLocalIdentifier: String?
    
    // MARK: View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkCameraAuthorizationStatus()
        checkPhotosAuthorizationStatus()
        checkAudioAuthorizationStatus()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session?.startRunning()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        previewLayer.frame = cameraView.bounds
    }
    
    func setupUI() {
        preViewImageView.layoutIfNeeded()
        preViewImageView.layer.cornerRadius = preViewImageView.frame.width / 2
        sutterButton.layer.cornerRadius = sutterButton.frame.size.width / 2
        sutterButton.layer.borderWidth = 5
        sutterButton.layer.borderColor = UIColor.systemGray3.cgColor
        cameraView.layer.addSublayer(previewLayer)
    }
    func checkAudioAuthorizationStatus() {
        func requestMicrophonePermission() {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    print("Audio access granted")
                } else {
                    self.popupAlert(title: "Audio access denied", message: "Audio permission is required for this app to record videos. Please grant permission from the app settings.")
                }
            }
        }
    }
    func checkPhotosAuthorizationStatus() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .notDetermined, .restricted, .denied, .limited :
                self.popupAlert(title: "Photos access denied", message: "Photos permission is required for this app to function. Please grant permission from the app settings.")
            case .authorized:
                print("Photos access granted")
            @unknown default:
                break
            }
        }
    }
    func checkCameraAuthorizationStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    self?.popupAlert(title: "Camera Permission Denied", message: "Camera permission is required for this app to function. Please grant permission from the app settings.")
                    return
                }
                DispatchQueue.main.async {
                    self?.setupCamera()
                }
            }
        case .restricted, .denied:
            popupAlert(title: "Camera Permission Denied", message: "Camera permission is required for this app to function. Please grant permission from the app settings.")
        case .authorized:
            setupCamera()
        @unknown default:
            break
        }
    }
    func popupAlert(title : String ,message : String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK: - Camera Setup Methods :-
extension CameraVC {
    func createCustomAlbumIfNeeded() {
        let albumName = "CustomCam"
        
        /// Check if the album already exists
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let customAlbum = collection.firstObject {
            /// The album already exists, store its localIdentifier
            customAlbumLocalIdentifier = customAlbum.localIdentifier
        } else {
            /// Create a new album
            PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            } completionHandler: {  success, error in
                if success {
                    /// Album created successfully, store its localIdentifier
                    if let customAlbum = collection.firstObject {
                        self.customAlbumLocalIdentifier = customAlbum.localIdentifier
                    }
                } else if let error = error {
                    print("Error creating album: \(error)")
                }
            }
        }
    }
    // Setting up the camera for images
    func setupCamera() {
        session = AVCaptureSession()
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) {
            do {
                input = try AVCaptureDeviceInput(device: device)
                if session?.canAddInput(input!) == true {
                    session?.addInput(input!)
                }
                if session?.canAddOutput(output) == true {
                    session?.addOutput(output)
                }
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                session?.sessionPreset = .photo
                if let session = session, !session.isRunning {
                    DispatchQueue.global(qos: .background).async {
                        session.startRunning()
                    }
                }
            } catch {
                print("Error setting up the camera: \(error.localizedDescription)")
            }
        }
    }
    // Setting up the camera for Videos
    func setupVideoCapture() {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition), let audio = AVCaptureDevice.default(for: .audio) {
            do {
                input = try AVCaptureDeviceInput(device: device)
                audioInput = try AVCaptureDeviceInput(device: audio)
                if session?.canAddInput(input!) == true {
                    session?.addInput(input!)
                    session?.addInput(audioInput!)
                }
                if session?.canAddOutput(movieOutput) == true {
                    session?.addOutput(movieOutput)
                }
                previewLayer.session = session
                session?.sessionPreset = .high
                if let session = session, !session.isRunning {
                    DispatchQueue.global(qos: .background).async {
                        session.startRunning()
                    }
                }
            } catch {
                print("Error setting up the camera: \(error.localizedDescription)")
            }
        }
    }
    
    // Start recording the video
    func startVideoRecording() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoFilename = "output.mp4"
        let videoPath = documentsDirectory.appendingPathComponent(videoFilename)
        movieOutput.startRecording(to: videoPath, recordingDelegate: self)
    }
    
    // Stop recording the video
    func stopVideoRecording() {
        movieOutput.stopRecording()
    }
    
    // Flashlight on-off Method
    func toggleFlash() {
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                try device.lockForConfiguration()
                if devicePosition == .back {
                    if device.hasTorch {
                        if device.torchMode == .on {
                            torchImageView.image = UIImage(systemName: "lightbulb")
                            device.torchMode = .off
                        } else {
                            try device.setTorchModeOn(level: 1.0)
                            torchImageView.image = UIImage(systemName: "lightbulb.fill")
                        }
                    }
                }
                device.unlockForConfiguration()
            } catch {
                print("Error toggling flash: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Click event methods :-

extension CameraVC {
    // Capture image and video button
    @IBAction func handleShutterButtonClick(_ sender: UIButton) {
        
        /// according to the camera mode (image/video) changeing the fuctionality of the button
        if isCapturingPhoto {
            /// if the camera mode is for image ...
            if let session = session, session.isRunning {
                output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            } else {
                setupCamera()
            }
        } else {
            /// if the camera mode is for video ...
            if isRecordingVideo {
                print("Video recording finished")
                timer?.invalidate()
                animateForRecording()
                stopVideoRecording()
                UIButton.animate(withDuration: 0.5) {
                    self.sutterButton.transform = .identity
                }
            } else {
                print("Video recording started")
                startTimer(duration: timeInterVal)
                startVideoRecording()
                UIButton.animate(withDuration: 0.5) {
                    self.sutterButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                    
                }
            }
            isRecordingVideo.toggle()
        }
    }
    
    // Toggle between front and back camera
    @objc func toggleCameraType() {
        /// toggle between front and back  camera
        devicePosition = (devicePosition == .back) ? .front : .back
        /// animation
        let rotationAngle: CGFloat = (devicePosition == .back) ? 0.0 : .pi
        UIView.animate(withDuration: 1.0) {
            self.toggleCameraImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
        }
        UIView.transition(with: cameraView, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            /// Removing input and output before switching camaeras
            if self.isCapturingPhoto {
                self.session?.removeInput(self.input!)
                self.session?.removeOutput(self.output)
                self.setupCamera()
            } else {
                self.session?.removeOutput(self.movieOutput)
                self.session?.removeInput(self.input!)
                self.session?.removeInput(self.audioInput!)
                self.setupVideoCapture()
            }
        }) {  done in
            if done {
                /// hiding the torch button for front camera
                if self.devicePosition == .front {
                    self.torchImageView.isHidden = true
                } else {
                    self.torchImageView.isHidden = false
                }
            }
        }
    }
    // Video timer  Action sheet
    @objc func showTimerActionSheet() {
        let alertController = UIAlertController(title: "Select maximum video duration", message: nil, preferredStyle: .actionSheet)
        let option1Action = UIAlertAction(title: "10 seconds", style: .default) { (action) in
            self.videoTimerImageView.image = UIImage(systemName: "10.circle.fill")
            self.timeInterVal = TimeInterval(10.0)
        }
        let option2Action = UIAlertAction(title: "20 seconds", style: .default) { (action) in
            self.videoTimerImageView.image = UIImage(systemName: "20.circle.fill")
            self.timeInterVal = TimeInterval(20.0)
        }
        let option3Action = UIAlertAction(title: "30 seconds", style: .default) { (action) in
            self.videoTimerImageView.image = UIImage(systemName: "30.circle.fill")
            self.timeInterVal = TimeInterval(30.0)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(option1Action)
        alertController.addAction(option2Action)
        alertController.addAction(option3Action)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func startTimer(duration: TimeInterval) {
        animateForRecording ()
        if let existingTimer = timer {
            existingTimer.invalidate()
        }
        /// timer for fixed video time
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.handleShutterButtonClick(UIButton())
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.videoTimerImageView.layer.opacity =  1
                self?.togglePhotoVideo.layer.opacity = 1
                self?.toggleCameraImageView.layer.opacity =  1
                self?.preViewImageView.layer.opacity =  1
                self?.torchImageViewLeftConstraint.constant = 10
                self?.view.layoutIfNeeded()
            }
            print("Timer fired!")
        }
    }
    func animateForRecording () {
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.videoTimerImageView.layer.opacity = self!.isRecordingVideo ? 1 : 0
            self?.togglePhotoVideo.layer.opacity = self!.isRecordingVideo ? 1 : 0
            self?.toggleCameraImageView.layer.opacity = self!.isRecordingVideo ? 1 : 0
            self?.preViewImageView.layer.opacity = self!.isRecordingVideo ? 1 : 0
            self?.torchImageViewLeftConstraint.constant = self!.isRecordingVideo ? 10 : 60
            self?.view.layoutIfNeeded()
        }
    }
    // Toggle between image mode and video mode
    @objc func togglePhotoVideoMode () {
        isCapturingPhoto.toggle()
        UIView.transition(with: cameraView, duration: 0.5, options: .transitionFlipFromLeft, animations: { [weak self] in
            if self!.isCapturingPhoto {
                print("Switched to photo mode")
                self!.togglePhotoVideo.image = UIImage(systemName: "camera")
                self!.sutterButton.backgroundColor = .clear
                /// removing  previous input and output
                self!.session?.removeInput(self!.input!)
                self!.session?.removeOutput(self!.movieOutput)
                self!.setupCamera()
                self!.videoTimerImageView.isHidden = true
            } else {
                print("Switched to video mode")
                self!.togglePhotoVideo.image = UIImage(systemName: "video")
                self!.sutterButton.backgroundColor = UIColor.red
                /// removing  previous input and output
                self!.session?.removeInput(self!.input!)
                self!.session?.removeOutput(self!.output)
                self!.setupVideoCapture()
                self!.videoTimerImageView.isHidden = false
            }
        }, completion:nil)
    }
    
    // To on-off the torch
    @objc func toggleTorch(){
        toggleFlash()
    }
    
    // View preview images
    @objc func viewImages() {
        session?.stopRunning()
        let destinationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewImagesVC") as! ViewImagesVC
        destinationVC.images = clickedImages
        navigationController?.pushViewController(destinationVC, animated: true)
    }
}

//MARK: - Capture photo Delegate :-

extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            return
        }
        print("Video output url : \(photo)")
        if let error = error {
            print("Image click error: \(error)")
        } else {
            print("Image clicked")
            
            /// check if custom album is avaliable
            /// if not then create album
            createCustomAlbumIfNeeded()
            preViewImageView.image = image
            /// accessing the album using local identifier
            if let albumLocalIdentifier = customAlbumLocalIdentifier {
                PHPhotoLibrary.shared().performChanges {
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumLocalIdentifier], options: nil).firstObject!)
                    let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset
                    albumChangeRequest?.addAssets([assetPlaceholder!] as NSArray)
                } completionHandler: { success, error in
                    if success {
                        print("Image saved to custom album")
                    } else if let error = error {
                        print("Error saving image: \(error)")
                    }
                }
            }
            clickedImages.insert(image, at: 0)
        }
    }
}

//MARK: - Record video Delegate :-

extension CameraVC: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Video recording finished with error: \(error)")
        } else {
            print("Video recording finished")
            
            /// check if custom album is avaliable
            /// if not then create album
            createCustomAlbumIfNeeded()
            print("Album identifier : \(customAlbumLocalIdentifier!)")
            /// accessing the album using local identifier
            if let albumLocalIdentifier = customAlbumLocalIdentifier {
                PHPhotoLibrary.shared().performChanges {
                    print("Video output url : \(outputFileURL)")
                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                    if let assetPlaceholder = assetRequest?.placeholderForCreatedAsset {
                        let albumChangeRequest = PHAssetCollectionChangeRequest(for: PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [albumLocalIdentifier], options: nil).firstObject!)
                        albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
                    }
                } completionHandler: { success, error in
                    if success {
                        print("Video saved to custom album")
                    } else if let error = error {
                        print("Error saving video: \(error)")
                    }
                }
            }
        }
    }
}

