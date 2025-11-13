//
//  ChromaVueApp.swift
//  ChromaVUE 3
//

import SwiftUI

struct ChromaVueApp: App {
    private let env = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            ContentView(
                startupViewModel: env.startupViewModel,
                sessionViewModel: env.sessionViewModel,
                cameraGateway: env.cameraGateway
            )
        }
    }
}
