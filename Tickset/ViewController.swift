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

    var captureSession:     AVCaptureSession?
    var videoPreviewLayer:  AVCaptureVideoPreviewLayer?
    var qrFrameView:        UIView?
    var currentMetadata:    String = ""
    var isStoped:           Bool = false
    var isFinalStatus:      Bool = false {
        didSet {
            if isFinalStatus {
                self.ui_message_show()
                self.tap_recognizer_enable()
            } else {
                self.ui_message_hide()
                self.tap_recognizer_disable()
            }
        }
    }
    
    @IBOutlet weak var continueLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    @IBAction func tapGestureAction(_ sender: Any) {
        if isStoped && isFinalStatus {
            isStoped = false
            self.ui_status_scan()
            self.ui_QRFrame_hide()
            self.startCapture()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.initCamera()
        self.ui_status_init()
        self.ui_loadingWheel_init()
        self.ui_QRFrame_init()
        self.ui_message_init()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if metadataObjects == nil || metadataObjects.count == 0 {
            self.ui_QRFrame_hide()
        } else {

            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            
            if metadataObj.type == AVMetadataObjectTypeQRCode {
                self.isStoped = true
                self.stopCapture()
                
                let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
                
                self.ui_QRFrame_add(bounds: barCodeObject.bounds)

                self.validationQR(metadata: metadataObj.stringValue)
            }
        }
    }
}

extension ViewController {
    
    func validationQR (metadata: String) {
        self.ui_status_checking()
        
        if MiddleWare.isValidURL(url_string: metadata) {
            print(">> URL {\(metadata)} is valid")
            let url = URL(string: metadata)!
            
            MiddleWare.get_status(url: url, completion: { (status, error) in
                switch status {
                case 200 :
                    //keep checking
                    MiddleWare.get_cookie(url: url, completion: { (cookie, error) in
                        if error == nil && cookie != nil {
                            MiddleWare.post_ticket(url: url, cookie: cookie!, completion: { (error) in
                                if error == nil {
                                    DispatchQueue.main.async {
                                        print(">> TICKET POSTED!")
                                        self.ui_status_valid()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        print(">> Error POST the ticket: {\(error)}\nTry again...")
                                        self.ui_status_error()
                                    }
                                }
                            })
                        } else {
                            DispatchQueue.main.async {
                                print(">> Error getting the Cookie: \n{\(cookie)}\n{\(error)}\nTry again...")
                                self.ui_status_error()
                            }
                        }
                    })
                    break
                case 202:
                    //ticket used
                    DispatchQueue.main.async {
                        print(">> Response status {\(status)}. Ticket has been used.")
                        self.ui_status_used()
                    }
                    break
                default:
                    DispatchQueue.main.async {
                        print(">> Response status {\(status)} is not 200.")
                        self.ui_status_invalid()
                    }
                    break
                }
            })
            
        } else {
            print(">> URL {\(metadata)} is NOT valid")
            self.ui_status_invalid()
        }
    }
    
    //MARK:- Video Capture functions
    func initCamera () {
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
        // as the media type parameter.
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let captureInput: AVCaptureInput
        do {
            try captureInput = AVCaptureDeviceInput(device: captureDevice)
            
            self.captureSession = AVCaptureSession()
            self.captureSession?.addInput(captureInput as AVCaptureInput)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            self.captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture.
            self.startCapture()
        } catch {
            print("Error: AVCaptureDeviceInput")
        }
    }
    
    func startCapture (withDelay: Bool=false) {
        self.captureSession?.startRunning()
    }
    
    func stopCapture () {
        self.captureSession?.stopRunning()
    }
}

//MARK:- GRAPHICAL HELPERS FUNTIONS
extension ViewController {
    //MARK: Tap Gesture Recognizer functions
    func tap_recognizer_enable () {
        if !self.tapGesture.isEnabled {
            self.tapGesture.isEnabled = true
        }
    }
    
    func tap_recognizer_disable () {
        if self.tapGesture.isEnabled {
            self.tapGesture.isEnabled = false
        }
    }
    //MARK: Tap to scan label funtions
    func ui_message_init () {
        self.continueLabel.text = "TAP TO SCAN\nNEXT TICKET"
        self.view.bringSubview(toFront: self.continueLabel)
        self.ui_message_hide()
    }
    
    func ui_message_show () {
        if self.continueLabel.isHidden {
            self.continueLabel.isHidden = false
        }
    }
    
    func ui_message_hide () {
        if !self.continueLabel.isHidden {
            self.continueLabel.isHidden = true
        }
    }
    //MARK: Label status funtions
    func ui_status_init () {
        self.view.bringSubview(toFront: self.messageLabel)
        self.ui_status_scan()
    }
    
    func ui_status_valid () {
        self.ui_loadingWheel_stop()
        self.messageLabel.text = "VALID\nTICKET"
        self.messageLabel.backgroundColor = Colors.green()
        self.messageLabel.textColor = Colors.white()
        self.isFinalStatus = true
    }
    
    func ui_status_invalid () {
        self.ui_loadingWheel_stop()
        self.messageLabel.text = "INVALID\nTICKET"
        self.messageLabel.backgroundColor = Colors.red()
        self.messageLabel.textColor = Colors.white()
        self.isFinalStatus = true
    }
    
    func ui_status_used () {
        self.ui_loadingWheel_stop()
        self.messageLabel.text = "USED\nTICKET"
        self.messageLabel.backgroundColor = Colors.orange()
        self.messageLabel.textColor = Colors.white()
        self.isFinalStatus = true
    }
    
    func ui_status_error () {
        self.ui_loadingWheel_stop()
        self.messageLabel.text = "ERROR\nTRY AGAIN"
        self.messageLabel.backgroundColor = Colors.orange()
        self.messageLabel.textColor = Colors.white()
        self.isFinalStatus = true
    }
    
    func ui_status_scan () {
        self.ui_loadingWheel_stop()
        self.messageLabel.text = "SCAN\nTICKET"
        self.messageLabel.backgroundColor = Colors.gray()
        self.messageLabel.textColor = Colors.white()
        self.isFinalStatus = false
    }
    
    func ui_status_checking () {
        self.ui_loadingWheel_start()
        self.messageLabel.text = ""
        self.messageLabel.backgroundColor = Colors.gray()
        self.messageLabel.textColor = Colors.white()
        self.isFinalStatus = false
    }
    
    //MARK: Loading Weel functions
    func ui_loadingWheel_init () {
        self.view.bringSubview(toFront: self.loadingWheel)
        self.loadingWheel.isHidden = true
    }
    
    func ui_loadingWheel_start () {
        if self.loadingWheel.isHidden {
            self.loadingWheel.isHidden = false
        }
        if !self.loadingWheel.isAnimating {
            self.loadingWheel.startAnimating()
        }
        
    }
    
    func ui_loadingWheel_stop () {
        if !self.loadingWheel.isHidden {
            self.loadingWheel.isHidden = true
            
        }
        if self.loadingWheel.isAnimating {
            self.loadingWheel.stopAnimating()
        }
    }
    
    //MARK: QR-code Frame functions
    func ui_QRFrame_init () {
        self.qrFrameView = UIView()
        self.qrFrameView!.layer.borderColor = Colors.ticksetGreen().cgColor
        self.qrFrameView!.layer.borderWidth = 2
        self.qrFrameView!.layer.cornerRadius = 10
        self.view.addSubview(qrFrameView!)
        self.view.bringSubview(toFront: self.qrFrameView!)

    }
    func ui_QRFrame_add (bounds: CGRect) {
        qrFrameView?.frame = bounds
    }
    
    func ui_QRFrame_hide () {
        qrFrameView?.frame = CGRect.zero
    }
    
    
}
