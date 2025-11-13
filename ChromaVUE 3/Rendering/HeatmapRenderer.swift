// Rendering/HeatmapRenderer.swift
// Converts ScalarGrid into a colored CGImage (CPU implementation).

import Foundation
import CoreGraphics
import ChromaDomain

/// Abstract interface for something that can render a ScalarGrid into a CGImage.
public protocol HeatmapRenderer {
    func makeImage(from grid: ScalarGrid) -> CGImage?
}

/// Simple CPU-based heatmap renderer.
/// Maps scalar values in [0, 1] to a blue → cyan → green → yellow → red ramp.
public final class CPUHeatmapRenderer: HeatmapRenderer {
    public static let shared = CPUHeatmapRenderer()

    private init() {}

    public func makeImage(from grid: ScalarGrid) -> CGImage? {
        let width = grid.width
        let height = grid.height
        guard width > 0, height > 0 else { return nil }

        // 4 bytes per pixel (RGBA8)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = bytesPerRow * height

        var data = Data(count: totalBytes)
        data.withUnsafeMutableBytes { (rawBuffer: UnsafeMutableRawBufferPointer) in
            guard let ptr = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }

            for y in 0..<height {
                for x in 0..<width {
                    let idx = y * width + x
                    let v = grid.values[idx]

                    let color = Self.colorForValue(v)

                    let pixelOffset = y * bytesPerRow + x * bytesPerPixel
                    ptr[pixelOffset + 0] = color.r
                    ptr[pixelOffset + 1] = color.g
                    ptr[pixelOffset + 2] = color.b
                    ptr[pixelOffset + 3] = color.a
                }
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let provider = CGDataProvider(data: data as CFData) else { return nil }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue:
                CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }

    // MARK: - Color ramp

    /// Map scalar value [0, 1] to RGBA (0–255).
    private static func colorForValue(_ rawValue: Float) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        // Clamp to [0, 1]
        let v = max(0, min(1, rawValue))

        // 0.0 -> blue, 0.25 -> cyan, 0.5 -> green, 0.75 -> yellow, 1.0 -> red
        let r: Float
        let g: Float
        let b: Float

        switch v {
        case 0..<0.25:
            // blue -> cyan
            let t = v / 0.25
            r = 0
            g = t
            b = 1
        case 0.25..<0.5:
            // cyan -> green
            let t = (v - 0.25) / 0.25
            r = 0
            g = 1
            b = 1 - t
        case 0.5..<0.75:
            // green -> yellow
            let t = (v - 0.5) / 0.25
            r = t
            g = 1
            b = 0
        default:
            // yellow -> red
            let t = (v - 0.75) / 0.25
            r = 1
            g = 1 - t
            b = 0
        }

        return (
            r: UInt8(max(0, min(255, Int(r * 255)))),
            g: UInt8(max(0, min(255, Int(g * 255)))),
            b: UInt8(max(0, min(255, Int(b * 255)))),
            a: 255
        )
    }
}
