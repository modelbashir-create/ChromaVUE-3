//
//  StartupViewModel.swift
//  ChromaVUE 3
//
//  Created by Mohamed Elbashir on 11/4/25.
//


// Presentation/StartupViewModel.swift
// ViewModel that drives startup & permission state.

import Foundation
import SwiftUI

@MainActor
final class StartupViewModel: ObservableObject {
    @Published var state: StartupState = .idle

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