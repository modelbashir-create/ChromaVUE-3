// UI/LaunchOverlay.swift
// Lightweight, brandable loading overlay for app startup.

import SwiftUI

struct LaunchOverlay: View {
    @ObservedObject var viewModel: StartupViewModel
    var brandTitle: String = "ChromaVue"

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "aqi.medium") // placeholder logo
                        .font(.system(size: 56, weight: .regular))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.primary)

                    Text(brandTitle)
                        .font(.title.bold())
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.top, 12)

                // Status text
                Text(statusLine(viewModel.state))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                // Spinner while not ready
                if !viewModel.isReady {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .padding(.top, 4)
                }

                // Permission help / actions
                if case .blockedPermission = viewModel.state {
                    VStack(spacing: 10) {
                        Text("Camera access is required to continue.")
                            .font(.callout)
                            .multilineTextAlignment(.center)

                        Button {
                            openSystemSettings()
                        } label: {
                            Label("Open Settings", systemImage: "gearshape")
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(.thinMaterial, in: Capsule())
                        }
                    }
                    .padding(.top, 6)
                }
            }
            .padding(20)
            .frame(maxWidth: 380)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Preparing \(brandTitle)")
    }

    private func statusLine(_ s: StartupState) -> String {
        switch s {
        case .idle:
            return "Idle"
        case .checkingPermissions:
            return "Checking camera permission"
        case .requestingPermissions:
            return "Requesting camera permission"
        case .ready:
            return "Ready"
        case .blockedPermission:
            return "Permission required"
        case .failed(let message):
            return "Error: \(message)"
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}