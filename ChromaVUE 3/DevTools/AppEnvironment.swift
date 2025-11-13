// App/AppEnvironment.swift
// Composition root wiring gateways, use cases, and view models.

import Foundation
import ChromaDomain
import ChromaUseCases

struct AppEnvironment {
    // Shared app-wide settings
    let appSettings: AppSettings

    // Concrete camera gateway for UI (ContentView / CameraPreview)
    let cameraGateway: AVFoundationCameraGateway

    // Use cases
    let sessionInteractor: SessionInteractor
    let startupInteractor: StartupInteractor
    let historyInteractor: HistoryInteractor

    // View models
    let sessionViewModel: SessionViewModel
    let startupViewModel: StartupViewModel

    static func bootstrap() -> AppEnvironment {
        // Settings
        let settings = AppSettings()

        // Concrete gateways (infrastructure)
        let camera = AVFoundationCameraGateway()
        let model = CoreMLModelGateway()
        let export = FileExportGatewayImpl()
        let permissions = SystemPermissionsGateway()
        let history = HistoryStoreGateway()

        // Use cases (depend on protocols from ChromaDomain)
        let sessionInteractor = SessionInteractor(
            camera: camera,     // seen as CameraGateway by the interactor
            model: model,       // ModelGateway
            export: export,     // ExportGateway
            sink: nil
        )

        let startupInteractor = StartupInteractor(
            permissions: permissions  // PermissionsGateway
        )

        let historyInteractor = HistoryInteractor(
            history: history           // HistoryGateway
        )

        // View models (main-actor, SwiftUI-facing)
        let sessionVM = SessionViewModel(
            sessionUseCase: sessionInteractor,
            settings: settings
        )

        let startupVM = StartupViewModel(
            startupUseCase: startupInteractor
        )

        // Wire session events into the VM
        Task {
            await sessionInteractor.setSink(sessionVM)
        }

        return AppEnvironment(
            appSettings: settings,
            cameraGateway: camera,
            sessionInteractor: sessionInteractor,
            startupInteractor: startupInteractor,
            historyInteractor: historyInteractor,
            sessionViewModel: sessionVM,
            startupViewModel: startupVM
        )
    }
}
