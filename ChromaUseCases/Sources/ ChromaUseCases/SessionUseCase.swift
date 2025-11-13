//
//  SessionUseCase.swift
//  ChromaVUE 3
//
//  Created by Mohamed Elbashir on 11/4/25.
//


// UseCases/SessionUseCase.swift
// Live session orchestration (clinical / dev), framework-free.

import Foundation
import ChromaDomain
// MARK: - Public API for presentation layer

public protocol SessionUseCase: Sendable {
    /// Start a live session in the given mode (clinical / training / developer).
    func startLiveSession(mode: SessionMode) async
    /// Stop the current live session, if any.
    func stopLiveSession() async
}

/// The presentation layer (ViewModel) implements this to receive session updates.
public protocol SessionEventsSink: AnyObject, Sendable {
    func sessionDidUpdate(_ state: LiveSessionState) async
}

// MARK: - Interactor

public actor SessionInteractor: SessionUseCase {
    private let camera: CameraGateway
    private let model: ModelGateway
    private let export: ExportGateway

    private weak var sink: SessionEventsSink?

    private var sessionID: SessionID?
    private var mode: SessionMode = .clinical
    private var frameCount: Int = 0
    private var running: Bool = false

    public init(
        camera: CameraGateway,
        model: ModelGateway,
        export: ExportGateway,
        sink: SessionEventsSink?
    ) {
        self.camera = camera
        self.model = model
        self.export = export
        self.sink = sink
    }

    /// Attach / replace the sink that receives LiveSessionState updates.
    public func setSink(_ sink: SessionEventsSink?) {
        self.sink = sink
    }

    // MARK: - SessionUseCase

    public func startLiveSession(mode: SessionMode) async {
        guard !running else { return }
        running = true
        self.mode = mode

        let id = SessionID()
        self.sessionID = id
        self.frameCount = 0

        // For clinical mode, config may be nil. For training, a TrainingUseCase
        // may call beginSession with a non-nil config.
        do {
            try await export.beginSession(id: id, config: nil as TrainingExportConfig?)
        } catch {
            // In a more advanced design we’d report this through a dedicated channel.
        }

        // Start camera streaming; frames are delivered to handleFrame(...)
        do {
            try await camera.startStreaming { [weak self] (meta: FrameMetadata, buffer: any Sendable) in
                guard let self else { return }
                await self.handleFrame(meta: meta, buffer: buffer)
            }
        } catch {
            // Failed to start camera; mark session as not running.
            running = false
            sessionID = nil
        }
    }

    public func stopLiveSession() async {
        guard running else { return }
        running = false

        let id = sessionID

        await camera.stopStreaming()

        if let id {
            await export.endSession(id: id)
        }

        sessionID = nil
        frameCount = 0
    }

    // MARK: - Internal

    private func handleFrame(meta: FrameMetadata, buffer: any Sendable) async {
        guard running, let sessionID else { return }

        // Maintain a simple 0…N frame index for the session.
        let idx = frameCount
        frameCount += 1

        let metaWithIndex = FrameMetadata(
            id: meta.id,
            timestampMS: meta.timestampMS,
            index: idx,
            torchPhase: meta.torchPhase,
            distanceMM: meta.distanceMM,
            tiltDeg: meta.tiltDeg
        )

        // 1) Run model to get a scalar map (e.g. StO₂).
        let scalar: ScalarGrid?
        do {
            scalar = try await model.infer(on: buffer, meta: metaWithIndex)
        } catch {
            scalar = nil
        }

        // 2) Compute QC flags (for now, optimistic stub).
        let qcFlags = QCFlags(
            inDistanceWindow: true,
            inTiltWindow: true,
            notSaturated: true,
            hasOnOffPair: true
        )
        let qcLevel = QCLevel.from(flags: qcFlags)

        // 3) Stats for scalar field (if present).
        let stats = scalar.map { computeSto2Stats(for: $0) }

        // 4) Build ProcessedFrame.
        let processed = ProcessedFrame(
            meta: metaWithIndex,
            qc: qcFlags,
            qcLevel: qcLevel,
            scalar: scalar,
            depth: nil,
            rgb: nil,
            sto2Stats: stats
        )

        // 5) Export frame (training vs clinical behavior decided in ExportGateway).
        await export.exportFrame(id: sessionID, processed: processed)

        // 6) Build LiveSessionState for presentation.
        let state = LiveSessionState(
            sessionID: sessionID,
            frameCount: frameCount,
            lastFrame: processed
        )

        // 7) Notify sink (ViewModel). The sink is usually @MainActor.
        await sink?.sessionDidUpdate(state)
    }
}

// MARK: - Helpers

private func computeSto2Stats(for grid: ScalarGrid) -> Sto2Stats {
    let v = grid.values
    guard let first = v.first else {
        return Sto2Stats(min: 0, mean: 0, max: 0)
    }
    var minV = first
    var maxV = first
    var sum: Float = 0
    for x in v {
        minV = min(minV, x)
        maxV = max(maxV, x)
        sum += x
    }
    return Sto2Stats(
        min: minV,
        mean: sum / Float(v.count),
        max: maxV
    )
}
