// Infrastructure/AVFoundationCameraGateway.swift
// Concrete CameraGateway using AVFoundation.

import Foundation
import AVFoundation

/// AVFoundation-based implementation of CameraGateway.
///
/// - Owns an AVCaptureSession and streams CVPixelBuffer frames to the handler.
/// - Does not know about SwiftUI or any UI concepts.
public final class AVFoundationCameraGateway: NSObject, CameraGateway {
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let queue = DispatchQueue(label: "camera.gateway.queue")

    private var handler: FrameHandler?

    private var isConfigured = false
    private var frameIndex: Int = 0
    private var sessionStartMS: Int64?

    public override init() {
        super.init()
    }

    // MARK: - CameraGateway

    public func startStreaming(handler: @escaping FrameHandler) async throws {
        self.handler = handler

        if !isConfigured {
            try configureSession()
            isConfigured = true
        }

        frameIndex = 0
        sessionStartMS = Int64(Date().timeIntervalSince1970 * 1000)

        session.startRunning()
    }

    public func stopStreaming() async {
        session.stopRunning()
        handler = nil
        sessionStartMS = nil
        frameIndex = 0
    }

    // MARK: - Private

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Input: back wide camera
        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .back)
        else {
            throw NSError(domain: "CameraGateway", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No back camera available"])
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw NSError(domain: "CameraGateway", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot add camera input"])
        }
        session.addInput(input)

        // Output: video frames
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                Int(kCVPixelFormatType_32BGRA)
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true

        guard session.canAddOutput(videoOutput) else {
            throw NSError(domain: "CameraGateway", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot add video output"])
        }
        session.addOutput(videoOutput)

        videoOutput.setSampleBufferDelegate(self, queue: queue)

        session.commitConfiguration()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension AVFoundationCameraGateway: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let handler = handler else { return }
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let nowMS = Int64(Date().timeIntervalSince1970 * 1000)
        let t0 = sessionStartMS ?? nowMS
        let relMS = max(0, nowMS - t0)

        let meta = FrameMetadata(
            timestampMS: relMS,
            index: frameIndex,
            torchPhase: .on,      // TODO: wire real torch phase
            distanceMM: nil,      // TODO: wire real depth distance if available
            tiltDeg: nil          // TODO: wire real tilt if available
        )
        frameIndex += 1

        // Call the async handler on a Task so we don't block the capture queue.
        Task {
            await handler(meta, pb as Any)
        }
    }
}