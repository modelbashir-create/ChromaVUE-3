import Foundation

// MARK: - Camera

public protocol CameraGateway: Sendable {
    /// Handler that receives frames from the camera.
    /// - Parameters:
    ///   - meta: Domain-level metadata about the frame.
    ///   - buffer: The underlying image buffer (typically a CVPixelBuffer in the
    ///             infrastructure layer), kept opaque but constrained to `any Sendable`.
    typealias FrameHandler = @Sendable (FrameMetadata, any Sendable) async -> Void

    func startStreaming(handler: @escaping FrameHandler) async throws
    func stopStreaming() async
}

// MARK: - Model

public protocol ModelGateway: Sendable {
    func infer(on buffer: any Sendable, meta: FrameMetadata) async throws -> ScalarGrid
}

// MARK: - Export

public protocol ExportGateway: Sendable {
    func beginSession(id: SessionID, config: TrainingExportConfig?) async throws
    func endSession(id: SessionID) async
    func exportFrame(id: SessionID, processed: ProcessedFrame) async
}

// MARK: - History

public protocol HistoryGateway: Sendable {
    func loadRecentSessions(limit: Int) async throws -> [SessionSummary]
}
