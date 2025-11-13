// Rendering/MetalHeatmapRenderer.swift
// Metal-based implementation of HeatmapRenderer using a compute shader.

import Foundation
import Metal
import CoreGraphics

/// Metal-backed heatmap renderer.
/// Converts a ScalarGrid into a colored CGImage using a compute kernel.
public final class MetalHeatmapRenderer: HeatmapRenderer {
    public static let shared = MetalHeatmapRenderer()

    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private let pipelineState: MTLComputePipelineState?

    private init() {
        let dev = MTLCreateSystemDefaultDevice()
        self.device = dev
        self.commandQueue = dev?.makeCommandQueue()

        // Try to load the default Metal library and the "heatmapKernel" function.
        if let dev,
           let library = try? dev.makeDefaultLibrary(),
           let function = library.makeFunction(name: "heatmapKernel") {
            self.pipelineState = try? dev.makeComputePipelineState(function: function)
        } else {
            self.pipelineState = nil
        }
    }

    public func makeImage(from grid: ScalarGrid) -> CGImage? {
        // Fallback if Metal isn't available or pipeline couldn't be created.
        guard let device = device,
              let queue = commandQueue,
              let pipeline = pipelineState else {
            return CPUHeatmapRenderer.shared.makeImage(from: grid)
        }

        let width = grid.width
        let height = grid.height
        guard width > 0, height > 0 else { return nil }

        // Create scalar input texture (.r32Float)
        let scalarDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r32Float,
            width: width,
            height: height,
            mipmapped: false
        )
        scalarDesc.usage = [.shaderRead]
        guard let scalarTex = device.makeTexture(descriptor: scalarDesc) else {
            return CPUHeatmapRenderer.shared.makeImage(from: grid)
        }

        // Upload scalar values to the texture
        var scalars = grid.values  // make mutable copy
        let bytesPerRowScalar = width * MemoryLayout<Float>.stride
        scalarTex.replace(
            region: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                              size: MTLSize(width: width, height: height, depth: 1)),
            mipmapLevel: 0,
            withBytes: &scalars,
            bytesPerRow: bytesPerRowScalar
        )

        // Create output color texture (.rgba8Unorm)
        let colorDesc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        colorDesc.usage = [.shaderWrite, .shaderRead]
        guard let colorTex = device.makeTexture(descriptor: colorDesc) else {
            return CPUHeatmapRenderer.shared.makeImage(from: grid)
        }

        // Encode compute pass
        guard let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return CPUHeatmapRenderer.shared.makeImage(from: grid)
        }

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(scalarTex, index: 0)
        encoder.setTexture(colorTex, index: 1)

        // Optional min/max uniforms – for now we just normalize by [0, 1] in shader.
        // If you want dynamic normalization, you can compute min/max here and pass
        // via a small uniform buffer.

        let w = pipeline.threadExecutionWidth
        let h = pipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSize(width: width, height: height, depth: 1)

        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Read back color texture into a CGImage
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = bytesPerRow * height
        var rawData = Data(count: totalBytes)

        rawData.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            if let base = ptr.baseAddress {
                colorTex.getBytes(
                    base,
                    bytesPerRow: bytesPerRow,
                    from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                                    size: MTLSize(width: width, height: height, depth: 1)),
                    mipmapLevel: 0
                )
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let provider = CGDataProvider(data: rawData as CFData) else { return nil }

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
}