// UI/PermissionView.swift
// Simple screen explaining why camera access is needed.

import SwiftUI

struct PermissionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .padding(.bottom, 8)

            Text("Camera Access Needed")
                .font(.title2.bold())

            Text("ChromaVue needs access to the camera to measure tissue oxygenation and show the live heatmap.")
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal)

            Button {
                guard let url = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url)
            } label: {
                Label("Open Settings", systemImage: "gearshape")
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundColor(.white)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}