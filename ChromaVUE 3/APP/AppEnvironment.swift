// App/AppEnvironment.swift
// Composition root wiring gateways, use cases, and view models.

import Foundation

struct AppEnvironment {
    // Gateways
    let cameraGateway: AVFoundationCameraGateway
    let modelGateway: CoreMLModelGateway
    let exportGateway: FileExportGatewayImpl
    let permissionsGateway: SystemPermissionsGateway
    let historyGateway: HistoryStoreGateway

    // Use cases
    let sessionInteractor: SessionInteractor
    let startupInteractor: StartupInteractor
    let historyInteractor: HistoryInteractor

    // View models
    let sessionViewModel: SessionViewModel
    let startupViewModel: StartupViewModel

    static func bootstrap() -> AppEnvironment {
        // Infrastructure
        let camera = AVFoundationCameraGateway()
        let model = CoreMLModelGateway()
        let export = FileExportGatewayImpl()
        let permissions = SystemPermissionsGateway()
        let history = HistoryStoreGateway()

        // Use cases
        let sessionInteractor = SessionInteractor(camera: camera,
                                                  model: model,
                                                  export: export,
                                                  sink: nil)
        let startupInteractor = StartupInteractor(permissions: permissions)
        let historyInteractor = HistoryInteractor(history: history)

        // View models
        let sessionVM = SessionViewModel(sessionUseCase: sessionInteractor)
        let startupVM = StartupViewModel(startupUseCase: startupInteractor)

        // Connect sink for session events
        Task {
            await sessionInteractor.setSink(sessionVM)
        }

        return AppEnvironment(
            cameraGateway: camera,
            modelGateway: model,
            exportGateway: export,
            permissionsGateway: permissions,
            historyGateway: history,
            sessionInteractor: sessionInteractor,
            startupInteractor: startupInteractor,
            historyInteractor: historyInteractor,
            sessionViewModel: sessionVM,
            startupViewModel: startupVM
        )
    }
}