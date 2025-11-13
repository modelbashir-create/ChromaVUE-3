// Domain/DomainTypes.swift
// Pure domain types for ChromaVue – no frameworks, no UI.

import Foundation

/// Camera authorization status for the camera, decoupled from AVFoundation.
public enum CameraAuthorizationStatus: Sendable {
    case authorized
    case denied
    case restricted
    case notDetermined
}

/// Abstraction over system permissions used by the startup flow.
public protocol PermissionsGateway: Sendable {
    /// Current camera authorization status.
    func cameraAuthorizationStatus() async -> CameraAuthorizationStatus

    /// Request camera access from the user and return whether it was granted.
    func requestCameraAccess() async -> Bool
}

/// Flash / LED phase for a given frame.
public enum TorchPhase: String, Codable, Sendable {
    case off
    case on
    case alternatingOn
    case alternatingOff
    case ambient
}

/// High-level session mode – how the app is being used.
public enum SessionMode: String, Codable, Sendable {
    case clinical     // normal, clinician-facing
    case training     // generates training data
    case developer    // dev-only features visible
}

/// User-facing flash / illumination mode.
public enum FlashMode: String, Codable, Sendable {
    case off
    case on
    case alternating
}

/// Simple opaque identifier for a session.
public struct SessionID: Hashable, Codable, Sendable {
    public let rawValue: UUID

    public init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

/// Metadata that describes a single captured frame.
public struct FrameMetadata: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    /// Milliseconds since the start of the camera session (t0 = 0).
    public let timestampMS: Int64
    /// Monotonic index within the session (0, 1, 2, …).
    public let index: Int
    /// Torch / flash state during this frame.
    public let torchPhase: TorchPhase
    /// Estimated distance from camera to target, in millimetres (if available).
    public let distanceMM: Float?
    /// Approximate tilt angle relative to optimal, in degrees (if available).
    public let tiltDeg: Float?

    public init(
        id: UUID = UUID(),
        timestampMS: Int64,
        index: Int,
        torchPhase: TorchPhase,
        distanceMM: Float?,
        tiltDeg: Float?
    ) {
        self.id = id
        self.timestampMS = timestampMS
        self.index = index
        self.torchPhase = torchPhase
        self.distanceMM = distanceMM
        self.tiltDeg = tiltDeg
    }
}

/// Fine-grained quality flags for a frame.
public struct QCFlags: Hashable, Codable, Sendable {
    public let inDistanceWindow: Bool
    public let inTiltWindow: Bool
    public let notSaturated: Bool
    public let hasOnOffPair: Bool

    public init(
        inDistanceWindow: Bool,
        inTiltWindow: Bool,
        notSaturated: Bool,
        hasOnOffPair: Bool
    ) {
        self.inDistanceWindow = inDistanceWindow
        self.inTiltWindow = inTiltWindow
        self.notSaturated = notSaturated
        self.hasOnOffPair = hasOnOffPair
    }
}

/// Coarse-grained quality classification, derived from QCFlags.
public enum QCLevel: String, Codable, Sendable {
    case good
    case warning
    case bad
}

/// Basic statistics for a scalar field (e.g. StO₂ map).
public struct Sto2Stats: Hashable, Codable, Sendable {
    public let min: Float
    public let mean: Float
    public let max: Float

    public init(min: Float, mean: Float, max: Float) {
        self.min = min
        self.mean = mean
        self.max = max
    }
}

// MARK: - QC derivation helpers

public extension QCLevel {
    static func from(flags: QCFlags) -> QCLevel {
        guard flags.inDistanceWindow,
              flags.inTiltWindow,
              flags.notSaturated else {
            return .bad
        }

        if flags.hasOnOffPair {
            return .good
        } else {
            return .warning
        }
    }
}
