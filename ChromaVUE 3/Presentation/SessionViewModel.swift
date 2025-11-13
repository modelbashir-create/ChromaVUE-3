// Presentation/SessionViewModel.swift
// ViewModel for the live camera/session screen.

import Foundation
import SwiftUI

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var sto2Text: String = "--"
    @Published var qcMessage: String = ""
    @Published var qcLevel: QCLevel = .good

    /// For now we just keep the last scalar grid; later you can turn this into CIImage/MTLTexture.
    @Published var lastScalarGrid: ScalarGrid?

    /// Current session mode (clinical/training/developer).
    @Published var mode: SessionMode = .clinical

    private let sessionUseCase: SessionUseCase

    init(sessionUseCase: SessionUseCase) {
        self.sessionUseCase = sessionUseCase
    }

    // MARK: - Intents

    func startClinical() {
        mode = .clinical
        isRunning = true
        Task {
            await sessionUseCase.startLiveSession(mode: .clinical)
        }
    }

    func startTraining() {
        mode = .training
        isRunning = true
        Task {
            await sessionUseCase.startLiveSession(mode: .training)
        }
    }

    func stop() {
        isRunning = false
        Task {
            await sessionUseCase.stopLiveSession()
        }
    }
}

// MARK: - SessionEventsSink

extension SessionViewModel: SessionEventsSink {
    func sessionDidUpdate(_ state: LiveSessionState) async {
        // Called from SessionInteractor (actor). We are @MainActor so UI updates are safe.
        guard let frame = state.lastFrame else { return }

        lastScalarGrid = frame.scalar
        qcLevel = frame.qcLevel

        if let stats = frame.sto2Stats {
            sto2Text = String(format: "%.0f%%", stats.mean * 100.0)
        } else {
            sto2Text = "--"
        }

        switch frame.qcLevel {
        case .good:
            qcMessage = "Good geometry"
        case .warning:
            qcMessage = "Check pairing / motion"
        case .bad:
            qcMessage = "Adjust distance / tilt"
        }
    }
}

// Enable use as a SessionEventsSink across actor boundaries.
extension SessionViewModel: @unchecked Sendable {}