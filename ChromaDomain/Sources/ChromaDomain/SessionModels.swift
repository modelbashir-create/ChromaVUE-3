// Domain/SessionModels.swift
// Domain-level session models used by UseCases and ViewModels.

import Foundation

/// Full processed frame, ready for export and UI.
public struct ProcessedFrame: Sendable {
    public let meta: FrameMetadata
    public let qc: QCFlags
    public let qcLevel: QCLevel
    public let scalar: ScalarGrid?
    public let depth: DepthGrid?
    public let rgb: RGBGrid?
    public let sto2Stats: Sto2Stats?

    public init(
        meta: FrameMetadata,
        qc: QCFlags,
        qcLevel: QCLevel,
        scalar: ScalarGrid?,
        depth: DepthGrid?,
        rgb: RGBGrid?,
        sto2Stats: Sto2Stats?
    ) {
        self.meta = meta
        self.qc = qc
        self.qcLevel = qcLevel
        self.scalar = scalar
        self.depth = depth
        self.rgb = rgb
        self.sto2Stats = sto2Stats
    }
}

/// Aggregate state of a live session.
public struct LiveSessionState: Sendable {
    public let sessionID: SessionID
    public let frameCount: Int
    public let lastFrame: ProcessedFrame

    public init(
        sessionID: SessionID,
        frameCount: Int,
        lastFrame: ProcessedFrame
    ) {
        self.sessionID = sessionID
        self.frameCount = frameCount
        self.lastFrame = lastFrame
    }
}
