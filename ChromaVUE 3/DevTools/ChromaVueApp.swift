//
//  ChromaVueApp.swift
//  ChromaVUE 3
//
//  Created by Mohamed Elbashir on 11/4/25.
//


// App/ChromaVueApp.swift

import SwiftUI

@main
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
