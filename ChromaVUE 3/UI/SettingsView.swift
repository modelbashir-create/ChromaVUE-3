//
//  SettingsView.swift
//  ChromaVue
//
//  Clean, modern settings driven by AppSettings
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Rendering

                Section(header: Text("Rendering")) {
                    Picker("Heatmap Engine", selection: $appSettings.heatmapBackend) {
                        ForEach(HeatmapBackend.allCases, id: \.self) { backend in
                            Text(backend.label).tag(backend)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(renderingFootnote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

                // MARK: - Future sections

                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ChromaVue")
                            .font(.headline)
                        Text("Experimental build for StO₂ visualization and data collection.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var renderingFootnote: String {
        switch appSettings.heatmapBackend {
        case .gpu:
            return "GPU rendering uses Metal for heatmap composition and will fall back to CPU if Metal is unavailable."
        case .cpu:
            return "CPU rendering uses a software pipeline and can be useful for debugging or older devices."
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = AppSettings()
        SettingsView(appSettings: settings)
    }
}
#endif