//
//  StartupViewModel.swift
//  ChromaVUE 3
//

// Presentation/StartupViewModel.swift
// ViewModel that drives startup & permission state.

import Foundation
import Combine
import SwiftUI
import ChromaUseCases

/// ViewModel responsible for evaluating startup conditions and driving the initial navigation / permissions UI.
@MainActor
final class StartupViewModel: ObservableObject {
    /// High-level startup state that drives the root navigation / permissions UI.
    @Published private(set) var state: StartupState = .idle

    private let startupUseCase: StartupUseCase

    init(startupUseCase: StartupUseCase) {
        self.startupUseCase = startupUseCase
    }

    func onAppear() {
        Task {
            await refreshStartupState()
        }
    }

    func refreshStartupState() async {
        state = .checkingPermissions
        let newState = await startupUseCase.evaluateStartupState()
        state = newState
    }

    func requestPermissions() {
        Task {
            state = .requestingPermissions
            let newState = await startupUseCase.requestPermissionsIfNeeded()
            state = newState
        }
    }

    var isReady: Bool {
        if case .ready = state { return true }
        return false
    }
}
