// UI/CameraPreview.swift
// SwiftUI wrapper for AVCaptureVideoPreviewLayer.

import SwiftUI
import AVFoundation

/// Simple UIView that hosts an AVCaptureVideoPreviewLayer.
final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

/// SwiftUI view that displays the camera preview from AVFoundationCameraGateway.
struct CameraPreview: UIViewRepresentable {
    let cameraGateway: AVFoundationCameraGateway

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = cameraGateway.captureSession
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Nothing to update dynamically for now.
    }
}
