//
//  ChromaVUE_3App.swift
//  ChromaVUE 3
//
//  Created by Mohamed Elbashir on 11/4/25.
//

import SwiftUI

@main
struct ChromaVUE_3App: App {
    /// Composition root for gateways, use cases, and view models.
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
