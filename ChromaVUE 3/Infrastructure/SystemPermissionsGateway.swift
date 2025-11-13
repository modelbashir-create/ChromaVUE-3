// Infrastructure/SystemPermissionsGateway.swift
// Concrete PermissionsGateway using AVFoundation.

import Foundation
import AVFoundation

/// Wraps AVFoundation's camera permission APIs in the PermissionsGateway protocol.
public final class SystemPermissionsGateway: PermissionsGateway {
    public init() {}

    public func cameraAuthorizationStatus() async -> CameraAuthorizationStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        @unknown default:
            return .restricted
        }
    }

    public func requestCameraAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}