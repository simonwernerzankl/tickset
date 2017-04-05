//
//  ViewController.swift
//  Tickset
//
//  Created by Carlos Martin on 22/2/17.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: - Properties
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var currentMetadata: String = ""
    var isStoped: Bool = false
    var isFinalStatus: Bool = false {
        didSet {
            if isFinalStatus {
                showMessage()
                enableTapRecognizer()
            } else {
                hideMessage()
                disableTapRecognizer()
            }
        }
    }
    
    @IBOutlet weak var cameraContainerView: UIView!
    @IBOutlet weak var qrFrameView: UIView! {
        didSet {
            qrFrameView.backgroundColor = .clear
            qrFrameView.layer.borderColor = UIColor.green.cgColor
            qrFrameView.layer.borderWidth = 2
        }
    }
    @IBOutlet weak var continueLabel: UILabel! {
        didSet {
            continueLabel.backgroundColor = .darkCyan
            continueLabel.text = "TAP TO SCAN NEXT QR CODE"
            hideMessage()
        }
    }
    @IBOutlet weak var messageLabel: UILabel! {
        didSet {
            messageLabel.backgroundColor = .darkCyan
            showScanStatus()
        }
    }
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView! {
        didSet { loadingWheel.isHidden = true }
    }
    @IBOutlet weak var tapGesture: UITapGestureRecognizer!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showInfoViewIfNeeded()
    }
    
    // MARK: - Actions
    
    @IBAction func tapGestureAction(_ sender: UITapGestureRecognizer) {
        
        if isStoped && isFinalStatus {
            
            isStoped = false
            showScanStatus()
            hideQRFrame()
            startCapture()
        }
    }
    
    // MARK: - QR and Camera Logic
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        if metadataObjects == nil || metadataObjects.count == 0 {
            hideQRFrame()
        } else {
            
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if metadataObj.type == AVMetadataObjectTypeQRCode {
                
                isStoped = true
                stopCapture()
                
                if let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj as AVMetadataMachineReadableCodeObject) as? AVMetadataMachineReadableCodeObject {
                
                    showQRFrame(with: barCodeObject.bounds)
                }
                
                validateQR(with: metadataObj.stringValue)
            }
        }
    }
    
    func validateQR(with metadata: String) {
        
        showCheckingStatus()
        
        if MiddleWare.isValidURL(for: metadata) {
            
            print(">> URL {\(metadata)} is valid")
            
            let url = URL(string: metadata)!
            MiddleWare.getStatus(with: url, completion: { (status, error) in
                
                switch status {
                case 200 :
                    // Keep checking
                    MiddleWare.getCookie(with: url, completion: { (cookie, error) in
                        
                        if error == nil && cookie != nil {
                            
                            MiddleWare.postTicket(with: url, cookie: cookie!, completion: { (error) in
                                
                                if error == nil {
                                    
                                    DispatchQueue.main.async {
                                        print(">> TICKET POSTED!")
                                        self.showValidStatus()
                                    }
                                    
                                } else {
                                    
                                    DispatchQueue.main.async {
                                        
                                        if let error = error {
                                            print(">> Error POST the ticket: {\(error)}\nTry again...")
                                        }
                                        self.showErrorStatus()
                                    }
                                }
                            })
                            
                        } else {
                            
                            DispatchQueue.main.async {
                                
                                if let error = error {
                                    print(">> Error getting the Cookie: \n{\(cookie ?? "")}\n{\(error)}\nTry again...")
                                }
                                self.showErrorStatus()
                            }
                        }
                    })
                    
                case 202:
                    // Ticket used
                    DispatchQueue.main.async {
                        print(">> Response status {\(status)}. Ticket has been used.")
                        self.showUsedStatus()
                    }
                    
                default:
                    DispatchQueue.main.async {
                        print(">> Response status {\(status)} is not 200.")
                        self.showInvalidStatus()
                    }
                }
            })
            
        } else {
            
            print(">> URL {\(metadata)} is NOT valid")
            showInvalidStatus()
        }
    }
    
    // MARK: - Video Capture
    
    func setupCamera() {
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
        // as the media type parameter.
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let captureInput: AVCaptureInput
        
        do {
            try captureInput = AVCaptureDeviceInput(device: captureDevice)
            
            captureSession = AVCaptureSession()
            captureSession?.addInput(captureInput as AVCaptureInput)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            cameraContainerView.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture.
            startCapture()
            
        } catch {
            print("Error: AVCaptureDeviceInput")
        }
    }
    
    func startCapture(with delay: Bool = false) {
        captureSession?.startRunning()
    }
    
    func stopCapture() {
        captureSession?.stopRunning()
    }
    
    // MARK: - Graphical Helpers

    // MARK: Tap Gesture Recognizer
    
    func enableTapRecognizer() {
        
        if tapGesture.isEnabled == false {
            tapGesture.isEnabled = true
        }
    }
    
    func disableTapRecognizer() {
        
        if tapGesture.isEnabled {
            tapGesture.isEnabled = false
        }
    }
    
    // MARK: Tap to scan label
    
    func showMessage() {
        
        if continueLabel.isHidden {
            continueLabel.isHidden = false
        }
    }
    
    func hideMessage() {
        
        if continueLabel.isHidden == false {
            continueLabel.isHidden = true
        }
    }
    
    // MARK: Label status
    
    func showValidStatus() {
        
        stopLoadingWheel()
        messageLabel.text = "VALID\nTICKET"
        messageLabel.backgroundColor = .limeGreen
        messageLabel.textColor = .white
        isFinalStatus = true
    }
    
    func showInvalidStatus() {
        
        stopLoadingWheel()
        messageLabel.text = "INVALID\nQR CODE"
        messageLabel.backgroundColor = .vividRed
        messageLabel.textColor = .white
        isFinalStatus = true
    }
    
    func showUsedStatus() {
        
        stopLoadingWheel()
        messageLabel.text = "USED\nTICKET"
        messageLabel.backgroundColor = .pureOrange
        messageLabel.textColor = .white
        isFinalStatus = true
    }
    
    func showErrorStatus() {
        
        stopLoadingWheel()
        messageLabel.text = "ERROR\nTRY AGAIN"
        messageLabel.backgroundColor = .pureOrange
        messageLabel.textColor = .white
        isFinalStatus = true
    }
    
    func showScanStatus() {
        
        stopLoadingWheel()
        messageLabel.text = "SCAN QR CODE ON TICKET"
        messageLabel.backgroundColor = .darkCyan
        messageLabel.textColor = .white
        isFinalStatus = false
    }
    
    func showCheckingStatus() {
        
        startLoadingWheel()
        messageLabel.text = ""
        messageLabel.backgroundColor = .darkCyan
        messageLabel.textColor = .white
        isFinalStatus = false
    }
    
    // MARK: Loading Weel
    
    func startLoadingWheel() {
        
        if loadingWheel.isHidden {
            loadingWheel.isHidden = false
        }
        
        if loadingWheel.isAnimating == false {
            loadingWheel.startAnimating()
        }
        
    }
    
    func stopLoadingWheel() {
        
        if loadingWheel.isHidden == false {
            loadingWheel.isHidden = true
            
        }
        if loadingWheel.isAnimating {
            loadingWheel.stopAnimating()
        }
    }
    
    // MARK: QR-code Frame
    
    func showQRFrame(with bounds: CGRect) {
        
        qrFrameView.frame = bounds
        qrFrameView.isHidden = false
        UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.qrFrameView.alpha = 1
        }, completion: nil)
    }
    
    func hideQRFrame() {
        
        UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
            self.qrFrameView.alpha = 0
        }) { (completed) in
            
            if completed {
                self.qrFrameView.isHidden = true
            }
        }
    }
    
    // MARK: - Info View
    
    func showInfoViewIfNeeded() {
        
        guard UserDefaults.standard.bool(forKey: "InfoViewShown") == false, let storyboard = self.storyboard else {
            return
        }
        
        let infoNavController = storyboard.instantiateViewController(withIdentifier: "InfoNavigationController")
        present(infoNavController, animated: true, completion: nil)
    }
    
}
