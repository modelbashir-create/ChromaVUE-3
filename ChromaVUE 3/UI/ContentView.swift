// UI/ContentView.swift
// Main camera screen, wired to SessionViewModel and StartupViewModel.

import SwiftUI

struct ContentView: View {
    @State private var isShowingSettings = false

    @ObservedObject var startupViewModel: StartupViewModel
    @ObservedObject var sessionViewModel: SessionViewModel

    /// Concrete camera gateway used only to feed CameraPreview.
    let cameraGateway: AVFoundationCameraGateway

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(cameraGateway: cameraGateway)
                .ignoresSafeArea()

            // Heatmap overlay (GPU or CPU based on settings)
            HeatmapOverlayView(
                grid: sessionViewModel.lastScalarGrid,
                useGPU: sessionViewModel.heatmapBackend == .gpu
            )

            // Simple HUD
            VStack {
                // Top overlay: StO₂ + QC
                VStack(spacing: 4) {
                    Text(sessionViewModel.sto2Text)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())

                    Text(sessionViewModel.qcMessage)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                }
                .padding(.top, 40)

                Spacer()

                // Bottom controls (unchanged)
                HStack(spacing: 16) {
                    Button(action: {
                        if sessionViewModel.isRunning {
                            sessionViewModel.stop()
                        } else {
                            sessionViewModel.startClinical()
                        }
                    }) {
                        Text(sessionViewModel.isRunning ? "Stop" : "Start")
                            .font(.headline)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundColor(.white)
                    }
                    .disabled(!startupViewModel.isReady)

                    Button(action: {
                        if sessionViewModel.isRunning {
                            sessionViewModel.stop()
                        }
                        sessionViewModel.startTraining()
                    }) {
                        Text("Training")
                            .font(.subheadline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(.thinMaterial, in: Capsule())
                    }
                    .disabled(!startupViewModel.isReady)
                }
                .padding(.bottom, 40)
            }
            .foregroundStyle(.white)
            .shadow(radius: 4)

            // Settings button overlay (top-right)
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        isShowingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 16)
                }
                Spacer()
            }

            // Startup overlay
            if !startupViewModel.isReady {
                LaunchOverlay(viewModel: startupViewModel)
                    .transition(.opacity)
            }
        }
        .onAppear {
            startupViewModel.onAppear()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(appSettings: sessionViewModel.settings)
        }
    }
}
