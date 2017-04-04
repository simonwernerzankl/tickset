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
    var qrFrameView: UIView?
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
    @IBOutlet weak var continueLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    @IBAction func tapGestureAction(_ sender: Any) {
        
        if isStoped && isFinalStatus {
            
            isStoped = false
            showScanStatus()
            hideQRFrame()
            startCapture()
        }
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        setupStatus()
        setupLoadingWheel()
        setupQRFrame()
        setupMessage()
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
                
                let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
                
                addQRFrame(to: barCodeObject.bounds)
                
                validationQR(metadata: metadataObj.stringValue)
            }
        }
    }
    
    func validationQR (metadata: String) {
        
        showCheckingStatus()
        
        if MiddleWare.isValidURL(urlString: metadata) {
            
            print(">> URL {\(metadata)} is valid")
            
            let url = URL(string: metadata)!
            MiddleWare.getStatus(url: url, completion: { (status, error) in
                
                switch status {
                case 200 :
                    // Keep checking
                    MiddleWare.getCookie(url: url, completion: { (cookie, error) in
                        
                        if error == nil && cookie != nil {
                            
                            MiddleWare.postTicket(url: url, cookie: cookie!, completion: { (error) in
                                
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
    
    func startCapture (withDelay: Bool=false) {
        captureSession?.startRunning()
    }
    
    func stopCapture() {
        captureSession?.stopRunning()
    }
    
    // MARK: - Graphical Helpers

    // MARK: Tap Gesture Recognizer functions
    
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
    
    // MARK: Tap to scan label funtions
    
    func setupMessage() {
        
        continueLabel.text = "TAP TO SCAN NEXT QR CODE"
        view.bringSubview(toFront: continueLabel)
        hideMessage()
    }
    
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
    
    // MARK: Label status funtions
    
    func setupStatus() {
        
        view.bringSubview(toFront: messageLabel)
        showScanStatus()
    }
    
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
        messageLabel.backgroundColor = .gray
        messageLabel.textColor = .white
        isFinalStatus = false
    }
    
    func showCheckingStatus() {
        
        startLoadingWheel()
        messageLabel.text = ""
        messageLabel.backgroundColor = .gray
        messageLabel.textColor = .white
        isFinalStatus = false
    }
    
    // MARK: Loading Weel functions
    
    func setupLoadingWheel() {
        
        view.bringSubview(toFront: loadingWheel)
        loadingWheel.isHidden = true
    }
    
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
    
    // MARK: QR-code Frame functions
    
    func setupQRFrame() {
        
        guard self.qrFrameView == nil else {
            return
        }
        
        let qrFrameView = UIView()
        qrFrameView.layer.borderColor = UIColor.green.cgColor
        qrFrameView.layer.borderWidth = 2
        qrFrameView.layer.cornerRadius = 10
        view.addSubview(qrFrameView)
        view.bringSubview(toFront: qrFrameView)
        self.qrFrameView = qrFrameView
    }
    
    func addQRFrame(to bounds: CGRect) {
        qrFrameView?.frame = bounds
    }
    
    func hideQRFrame() {
        qrFrameView?.frame = CGRect.zero
    }
    
}
