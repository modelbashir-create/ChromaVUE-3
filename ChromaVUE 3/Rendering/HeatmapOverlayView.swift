// Rendering/HeatmapOverlayView.swift
// SwiftUI overlay that renders a ScalarGrid as a heatmap image.

import SwiftUI

struct HeatmapOverlayView: View {
    let grid: ScalarGrid?
    var renderer: HeatmapRenderer = CPUHeatmapRenderer.shared

    @State private var cgImage: CGImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let cgImage {
                    // Stretch to fill, preserving aspect ratio.
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
            .onAppear {
                updateImage()
            }
            .onChange(of: grid?.width) { _ in
                updateImage()
            }
            .onChange(of: grid?.height) { _ in
                updateImage()
            }
            .onChange(of: grid?.values.count) { _ in
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
        cgImage = renderer.makeImage(from: grid)
    }
}