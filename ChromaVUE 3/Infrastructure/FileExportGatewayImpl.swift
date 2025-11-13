// Infrastructure/FileExportGatewayImpl.swift
// Concrete ExportGateway using the file system (JSONL + .bin).

import Foundation
import ChromaDomain

/// File system–backed implementation of ExportGateway.
///
/// - Creates a folder per session under Documents/ChromaSessions.
/// - Optionally writes a minimal JSONL file of per-frame summary records.
/// - Optionally writes .bin float grids for scalar/depth/RGB if enabled.
public actor FileExportGatewayImpl: ChromaDomain.ExportGateway {
    private struct SessionRecord {
        let id: SessionID
        let folder: URL
        let config: TrainingExportConfig?
        var jsonlHandle: FileHandle?
    }

    private var sessions: [UUID: SessionRecord] = [:]

    public init() {}

    // MARK: - ExportGateway conformance

    public func beginSession(id: SessionID, config: TrainingExportConfig?) async throws {
        let root = try ensureRootFolder()
        let folder = root.appendingPathComponent(id.rawValue.uuidString, isDirectory: true)

        let fm = FileManager.default
        try fm.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)

        var jsonlHandle: FileHandle? = nil
        if config?.enableJSONL == true {
            let jsonlURL = folder.appendingPathComponent("frames.jsonl")
            fm.createFile(atPath: jsonlURL.path, contents: nil, attributes: nil)
            jsonlHandle = try FileHandle(forWritingTo: jsonlURL)
        }

        let record = SessionRecord(
            id: id,
            folder: folder,
            config: config,
            jsonlHandle: jsonlHandle
        )
        sessions[id.rawValue] = record
    }

    public func endSession(id: SessionID) async {
        guard let record = sessions.removeValue(forKey: id.rawValue) else { return }
        do {
            try record.jsonlHandle?.close()
        } catch {
            // Optional: dev logging
        }
    }

    public func exportFrame(id: SessionID, processed: ProcessedFrame) async {
        guard let record = sessions[id.rawValue] else { return }

        // 1) JSONL: write a minimal, hand-crafted JSON line (no Encodable requirement).
        if record.config?.enableJSONL == true, let handle = record.jsonlHandle {
            let meta = processed.meta
            let qcLevel = processed.qcLevel
            let sto2Mean = processed.sto2Stats?.mean ?? -1

            // Very small, flat JSON item to make training/debugging easier.
            let jsonLine = """
            {"timestampMS":\(meta.timestampMS),"index":\(meta.index),"qcLevel":"\(qcLevel.rawValue)","sto2Mean":\(sto2Mean)}
            """

            if let data = (jsonLine + "\n").data(using: .utf8) {
                do {
                    try handle.write(contentsOf: data)
                } catch {
                    // Optional: dev logging
                }
            }
        }

        // 2) Binary grids: scalar / depth / RGB as float32 .bin files.
        if record.config?.enableBinGrids == true {
            let folder = record.folder
            let index = processed.meta.index

            if let scalar = processed.scalar {
                let url = folder.appendingPathComponent("scalar_\(index).bin")
                writeFloatGrid(scalar.values, to: url)
            }

            if let depth = processed.depth {
                let url = folder.appendingPathComponent("depth_\(index).bin")
                writeFloatGrid(depth.values, to: url)
            }

            if let rgbGrid = processed.rgb {
                let url = folder.appendingPathComponent("rgb_\(index).bin")

                // Flatten RGBPixel(r,g,b) into an interleaved float array [r,g,b,r,g,b,...].
                var values: [Float] = []
                values.reserveCapacity(rgbGrid.width * rgbGrid.height * 3)

                for pixel in rgbGrid.pixels {
                    values.append(pixel.r)
                    values.append(pixel.g)
                    values.append(pixel.b)
                }

                writeFloatGrid(values, to: url)
            }
        }

        // Re-store the record (in case we modify it in the future, e.g. counters).
        sessions[id.rawValue] = record
    }

    // MARK: - Helpers

    private func ensureRootFolder() throws -> URL {
        let fm = FileManager.default
        let docs = try fm.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let root = docs.appendingPathComponent("ChromaSessions", isDirectory: true)
        try fm.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)
        return root
    }

    private func writeFloatGrid(_ values: [Float], to url: URL) {
        let data = values.withUnsafeBufferPointer { ptr in
            Data(buffer: ptr)
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            // Optional: dev logging
        }
    }
}
