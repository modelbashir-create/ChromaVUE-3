// Presentation/SessionViewModel.swift
// ViewModel for the live camera/session screen.

import Foundation
import SwiftUI
import Combine
import ChromaDomain
import ChromaUseCases

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var sto2Text: String = "--"
    @Published var qcMessage: String = ""
    @Published var qcLevel: QCLevel = .good

    /// Latest scalar grid (StO₂ map).
    @Published var lastScalarGrid: ScalarGrid?

    /// Current session mode (clinical/training/developer).
    @Published var mode: SessionMode = .clinical

    /// Shared app settings (including heatmap backend).
    let settings: AppSettings

    private var settingsCancellable: AnyCancellable?

    /// Convenience mirror so views can bind via the VM.
    var heatmapBackend: HeatmapBackend {
        get { settings.heatmapBackend }
        set { settings.heatmapBackend = newValue }
    }

    private let sessionUseCase: SessionUseCase

    init(sessionUseCase: SessionUseCase, settings: AppSettings) {
        self.sessionUseCase = sessionUseCase
        self.settings = settings
        settingsCancellable = settings.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
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
        let frame = state.lastFrame

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

extension SessionViewModel: @unchecked Sendable {}
