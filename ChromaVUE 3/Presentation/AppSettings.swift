// Presentation/AppSettings.swift
// Shared app-wide settings (rendering backend, dev flags, etc.)

import Foundation
import Combine
import SwiftUI
import ChromaDomain

/// Rendering backend for the heatmap overlay.
enum HeatmapBackend: String, CaseIterable, Codable, Sendable {
    case gpu
    case cpu

    var label: String {
        switch self {
        case .gpu: return "GPU"
        case .cpu: return "CPU"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    // Default mode used when starting a new session from the main screen.
    @Published var defaultSessionMode: SessionMode = .clinical

    // Rendering backend for the heatmap overlay.
    @Published var heatmapBackend: HeatmapBackend = .gpu {
        didSet { persistHeatmapBackend() }
    }

    // Clinical capture & export settings (training ignores these).
    @Published var captureHEICStills: Bool = true
    @Published var captureRAWStills: Bool = false
    @Published var captureJSONLMetadata: Bool = false
    @Published var captureBinGrids: Bool = false

    private let backendKey = "heatmapBackend"

    init() {
        loadHeatmapBackend()
    }

    private func loadHeatmapBackend() {
        let raw = UserDefaults.standard.string(forKey: backendKey)
        if let raw, let backend = HeatmapBackend(rawValue: raw) {
            heatmapBackend = backend
        } else {
            heatmapBackend = .gpu // default
        }
    }

    private func persistHeatmapBackend() {
        UserDefaults.standard.set(heatmapBackend.rawValue, forKey: backendKey)
    }
}
