//
//  SettingsView.swift
//  ChromaVUE 3
//
//  Clean, sectioned settings driven by AppSettings
//

import SwiftUI
import ChromaDomain

struct SettingsView: View {
    @ObservedObject var appSettings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Mode

                Section(header: Text("Mode")) {
                    Picker("Mode", selection: $appSettings.defaultSessionMode) {
                        Text("Clinical").tag(SessionMode.clinical)
                        Text("Training").tag(SessionMode.training)
                    }
                    .pickerStyle(.segmented)

                    Text("This selects the default mode used when starting a new session from the main screen. Training mode always uses a fixed export configuration.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }

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

                // MARK: - Capture & Export

                Section(
                    header: Text("Capture & Export"),
                    footer: Text("These options apply to clinical sessions. Training sessions always export full metadata, grids, and matched RAW/HEIC stills for model development.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                ) {
                    Toggle("Save HEIC stills (clinical)", isOn: $appSettings.captureHEICStills)
                    Toggle("Save RAW stills (clinical)", isOn: $appSettings.captureRAWStills)
                    Toggle("Save JSONL metadata (clinical)", isOn: $appSettings.captureJSONLMetadata)
                    Toggle("Save .bin grids (clinical)", isOn: $appSettings.captureBinGrids)
                }

                // MARK: - About

                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appName)
                            .font(.headline)
                        Text(versionString)
                            .font(.subheadline)
                        Text("Experimental build for StO₂ visualization and training data collection. Not for clinical use.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Helpers

    private var renderingFootnote: String {
        switch appSettings.heatmapBackend {
        case .gpu:
            return "GPU rendering uses Metal for heatmap composition and will fall back to CPU if Metal is unavailable."
        case .cpu:
            return "CPU rendering uses a software pipeline and can be useful for debugging or older devices."
        }
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ??
        "ChromaVue"
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "Version \(version) (\(build))"
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
