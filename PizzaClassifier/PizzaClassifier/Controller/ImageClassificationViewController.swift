//
//  ViewController.swift
//  PizzaClassifier
//
//  Created by Antonio Chiappetta on 31/01/2020.
//  Copyright © 2020 Antonio Chiappetta. All rights reserved.
//

import UIKit
import Vision
import CoreML
import CoreMedia

class ImageClassificationViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var resultsView: UIView!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    // MARK: - Properties - VideoCapture
    
    var videoCapture: VideoCapture!
    let semaphore = DispatchSemaphore(value: ImageClassificationViewController.maxRequests)
    let fpsCounter = FPSCounter()
    
    // MARK: - Properties - Predictions
    
    lazy var visionModel: VNCoreMLModel = {
        do {
            let pizzaClassifier = Pizza()
            return try VNCoreMLModel(for: pizzaClassifier.model)
        } catch {
            fatalError("Failed to create VNCoreMLModel")
        }
    }()
    
    var classificationRequests = [VNCoreMLRequest]()
    var currentRequest = 0
    static let maxRequests = 2
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupUI()
        self.setupVision()
        self.setupCamera()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        resizePreviewLayer()
    }
    
    // MARK: - Setup
    
    func setupUI() {
        resultsLabel.text = ""
        fpsLabel.text = ""
    }
    
    func setupVision() {
        for _ in 0..<ImageClassificationViewController.maxRequests {
            let request = VNCoreMLRequest(model: visionModel) { [weak self] (request, error) in
                self?.processObservations(for: request, error: error)
            }
            
            request.imageCropAndScaleOption = .centerCrop
            classificationRequests.append(request)
        }
    }
    
    func setupCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        
        // Frequency is 30 / frameInterval captures per second
        videoCapture.frameInterval = 15
        
        videoCapture.setUp(sessionPreset: .high) { (success) in
            if success {
                // Add the video preview layer to the UI
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                self.fpsCounter.start()
                self.videoCapture.start()
            }
        }
    }
    
    // MARK: - Preview
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    // MARK: - Predictions
    
    func classify(sampleBuffer: CMSampleBuffer) {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // Tell Vision about the orientation of the image
            let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
            
            // Get additional info from the camera
            var options: [VNImageOption : Any] = [ : ]
            if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
                options[.cameraIntrinsics] = cameraIntrinsicMatrix
            }
            
            // The semaphore is used to block the VideoCapure queue and drop frames when CoreML cannot keep up
            semaphore.wait()
            
            // For better throughput, we want to schedule multiple Vision requests in parallel.
            let request = self.classificationRequests[currentRequest]
            currentRequest += 1
            if currentRequest >= ImageClassificationViewController.maxRequests {
                currentRequest = 0
            }
            
            // For better throughput, perform predictions on a background queue, instead of the VideoCapure queue.
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: options)
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform classification: \(error)")
            }
            
            semaphore.signal()
        }
    }
    
    func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNClassificationObservation] {
                if results.isEmpty {
                    self.resultsLabel.text = "Nothing found"
                } else {
                    let topResults = results.prefix(2).map({
                        observation in
                        String(format: "%@ %.1f%%", observation.identifier, observation.confidence * 100)
                    })
                    self.resultsLabel.text = topResults.joined(separator: "\n")
                }
            } else if let error = error {
                self.resultsLabel.text = "Error: \(error.localizedDescription)"
            } else {
                self.resultsLabel.text = "Unknown error"
            }
            
            self.fpsCounter.frameCompleted()
            self.fpsLabel.text = String(format: "%.1f FPS", self.fpsCounter.fps)
        }
    }


}

// MARK: - Extensions

extension ImageClassificationViewController: VideoCaptureDelegate {
    
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
        classify(sampleBuffer: sampleBuffer)
    }
    
}

