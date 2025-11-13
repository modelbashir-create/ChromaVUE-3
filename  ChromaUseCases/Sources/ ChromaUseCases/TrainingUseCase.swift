// UseCases/TrainingUseCase.swift
// Training-specific orchestration (export configuration, markers).

import Foundation

public protocol TrainingUseCase: Sendable {
    /// Start a training session with the given export configuration.
    func startTrainingSession(config: TrainingExportConfig) async

    /// Stop the current training session (if any).
    func stopTrainingSession() async

    /// Mark an event during training (e.g. “baseline”, “occlusion”, etc.).
    func markEvent(note: String?) async
}

public actor TrainingInteractor: TrainingUseCase {
    private let session: SessionInteractor
    private let export: ExportGateway

    private var trainingConfig: TrainingExportConfig?
    private var trainingSessionID: SessionID?

    public init(session: SessionInteractor,
                export: ExportGateway) {
        self.session = session
        self.export = export
    }

    public func startTrainingSession(config: TrainingExportConfig) async {
        guard trainingSessionID == nil else { return }

        let id = SessionID()
        trainingSessionID = id
        trainingConfig = config

        // Configure export layer for training (JSONL, CSV, RAW/HEIC).
        do {
            try await export.beginSession(id: id, config: config)
        } catch {
            // In a more advanced design, you might report this to a VM/error sink.
        }

        // Start underlying live session in training mode.
        await session.startLiveSession(mode: .training)
    }

    public func stopTrainingSession() async {
        guard let id = trainingSessionID else { return }

        trainingSessionID = nil
        trainingConfig = nil

        await session.stopLiveSession()
        await export.endSession(id: id)
    }

    public func markEvent(note: String?) async {
        // You can extend ExportGateway with an exportEvent(...) function and call it here.
        // For now this is a placeholder hook; presentation can still model the intent.
    }
}
