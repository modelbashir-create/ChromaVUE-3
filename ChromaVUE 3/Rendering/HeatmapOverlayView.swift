// Rendering/HeatmapOverlayView.swift
// SwiftUI overlay that renders a ScalarGrid as a heatmap image.


import SwiftUI
import ChromaDomain

struct HeatmapOverlayView: View {
    let grid: ScalarGrid?
    /// If true, try GPU (Metal) first; otherwise use CPU renderer.
    var useGPU: Bool

    @State private var cgImage: CGImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let cgImage {
                    Image(decorative: cgImage,
                          scale: 1,
                          orientation: .up)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blendMode(.plusLighter)
                        .opacity(0.8)
                } else {
                    Color.clear
                }
            }
            .onAppear { updateImage() }
            .onChange(of: grid?.width) {
                updateImage()
            }
            .onChange(of: grid?.height) {
                updateImage()
            }
            .onChange(of: grid?.values.count) {
                updateImage()
            }
            .onChange(of: useGPU) {
                updateImage()
            }
        }
        .allowsHitTesting(false)
    }

    private func updateImage() {
        guard let grid else {
            cgImage = nil
            return
        }

        let renderer: HeatmapRenderer = useGPU
            ? MetalHeatmapRenderer.shared   // GPU (falls back to CPU internally)
            : CPUHeatmapRenderer.shared     // force CPU

        cgImage = renderer.makeImage(from: grid)
    }
}
