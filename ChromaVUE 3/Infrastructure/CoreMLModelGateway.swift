//
//  CoreMLModelGateway.swift
//  ChromaVUE 3
//
//  Concrete ModelGateway using CoreML / Vision.
//

import Foundation
import CoreML
@preconcurrency import Vision
import CoreVideo
import ChromaDomain

public enum ModelGatewayError: Error {
    case invalidBufferType
    case modelNotLoaded
    case inferenceFailed(String)
}

/// CoreML-based implementation of ModelGateway.
///
/// This is structured so you can plug in your actual CoreML model easily.
/// For now, it supports a Vision pipeline (VNCoreMLModel + VNCoreMLRequest).
public final class CoreMLModelGateway: ChromaDomain.ModelGateway {
    private let vnModel: VNCoreMLModel?

    /// Configure with a pre-constructed MLModel or with your own wrapper if you like.
    public init() {
        // TODO: Replace with your actual model load.
        // Example:
        // let configuration = MLModelConfiguration()
        // configuration.computeUnits = .all
        // let coreML = try? MySto2Model(configuration: configuration).model
        // self.vnModel = try? VNCoreMLModel(for: coreML)
        self.vnModel = nil
    }

    // MARK: - ModelGateway

    public func infer(on buffer: any Sendable, meta: ChromaDomain.FrameMetadata) async throws -> ChromaDomain.ScalarGrid {
        // The camera pipeline is expected to always pass a CVPixelBuffer here.
        // If that invariant is broken, this is a programmer error.
        let pixelBuffer = buffer as! CVPixelBuffer

        // If no model is loaded, return a dummy grid so the pipeline stays wired up.
        guard let vnModel = vnModel else {
            let side = 32
            let values = Array(repeating: Float(0.5), count: side * side)
            return ChromaDomain.ScalarGrid(width: side, height: side, values: values)
        }

        return try await runVisionInference(vnModel: vnModel, pixelBuffer: pixelBuffer)
    }

    // MARK: - Vision pipeline

    private func runVisionInference(
        vnModel: VNCoreMLModel,
        pixelBuffer: CVPixelBuffer
    ) async throws -> ChromaDomain.ScalarGrid {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: vnModel) { request, error in
                if let error {
                    continuation.resume(throwing: ModelGatewayError.inferenceFailed(error.localizedDescription))
                    return
                }

                guard let results = request.results else {
                    continuation.resume(throwing: ModelGatewayError.inferenceFailed("No results"))
                    return
                }

                // Common patterns:
                // - VNCoreMLFeatureValueObservation (MLMultiArray)
                // - VNPixelBufferObservation
                if let feature = results.compactMap({ $0 as? VNCoreMLFeatureValueObservation }).first,
                   let multiArray = feature.featureValue.multiArrayValue {
                    let grid = Self.scalarGrid(from: multiArray)
                    continuation.resume(returning: grid)
                    return
                }

                if let pixelObs = results.compactMap({ $0 as? VNPixelBufferObservation }).first {
                    let grid = Self.scalarGrid(from: pixelObs.pixelBuffer)
                    continuation.resume(returning: grid)
                    return
                }

                continuation.resume(throwing: ModelGatewayError.inferenceFailed("Unsupported model output type"))
            }

            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .up,
                options: [:]
            )

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ModelGatewayError.inferenceFailed(error.localizedDescription))
            }
        }
    }

    // MARK: - Helpers to convert model outputs → ScalarGrid

    /// Convert MLMultiArray (e.g. 1×1×H×W or 1×H×W) to ScalarGrid.
    private static func scalarGrid(from array: MLMultiArray) -> ChromaDomain.ScalarGrid {
        let shape = array.shape.map { Int(truncating: $0) }

        // Try to infer H×W from the trailing dimensions.
        let height: Int
        let width: Int
        if shape.count >= 2 {
            height = shape[shape.count - 2]
            width = shape[shape.count - 1]
        } else {
            let count = array.count
            let side = Int(sqrt(Double(count)).rounded(.down))
            height = side
            width = side
        }

        var values = [Float](repeating: 0, count: width * height)
        let maxCount = min(array.count, values.count)
        for i in 0..<maxCount {
            values[i] = Float(truncating: array[i])
        }

        return ChromaDomain.ScalarGrid(width: width, height: height, values: values)
    }

    /// Convert a grayscale CVPixelBuffer to ScalarGrid.
    private static func scalarGrid(from pixelBuffer: CVPixelBuffer) -> ChromaDomain.ScalarGrid {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let count = width * height

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            let values = [Float](repeating: 0, count: count)
            return ChromaDomain.ScalarGrid(width: width, height: height, values: values)
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        var values = [Float](repeating: 0, count: count)

        for y in 0..<height {
            let rowPtr = baseAddress.advanced(by: y * bytesPerRow)
            let row = rowPtr.bindMemory(to: UInt8.self, capacity: width)
            for x in 0..<width {
                let idx = y * width + x
                let v = Float(row[x]) / 255.0
                values[idx] = v
            }
        }

        return ChromaDomain.ScalarGrid(width: width, height: height, values: values)
    }
}
