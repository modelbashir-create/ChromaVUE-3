// Infrastructure/CoreMLModelGateway.swift
// Concrete ModelGateway using CoreML / Vision (placeholder implementation).

import Foundation
import CoreML
import Vision

/// Error type for the CoreML model gateway.
public enum ModelGatewayError: Error {
    case invalidBufferType
    case modelNotLoaded
    case inferenceFailed(String)
}

/// CoreML-based implementation of ModelGateway.
///
/// Right now this is a stub that returns a dummy scalar grid.
/// You can later wire your real model here.
public final class CoreMLModelGateway: ModelGateway {
    // Replace this with your actual MLModel / VNCoreMLModel
    private let model: VNCoreMLModel?

    public init() {
        // TODO: load your real CoreML model here.
        // Example:
        // let mlModel = try? MySto2Model(configuration: MLModelConfiguration()).model
        // self.model = try? VNCoreMLModel(for: mlModel)
        self.model = nil
    }

    public func infer(on buffer: Any, meta: FrameMetadata) async throws -> ScalarGrid {
        // For now, return a dummy 32×32 grid at 0.5 to keep the pipeline flowing.
        guard let _ = buffer as? AnyObject else {
            throw ModelGatewayError.invalidBufferType
        }

        let width = 32
        let height = 32
        let values = Array(repeating: Float(0.5), count: width * height)
        return ScalarGrid(width: width, height: height, values: values)

        // When wiring the real model:
        // 1. Cast `buffer` to CVPixelBuffer
        // 2. Run VNCoreMLRequest or direct model prediction
        // 3. Convert the output MLMultiArray / CVPixelBuffer into ScalarGrid
    }
}
