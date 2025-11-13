// Infrastructure/FileExportGateway.swift
// Concrete ExportGateway using the file system (JSONL + .bin in future).

import Foundation

/// File system–backed implementation of ExportGateway.
///
/// - Creates a folder per session under Documents/ChromaSessions.
/// - Writes a JSONL file of ProcessedFrame records.
/// - You can extend this later to write .bin float grids and CSVs.
public actor FileExportGatewayImpl: ExportGateway {
    private struct SessionRecord {
        let id: SessionID
        let folder: URL
        let config: TrainingExportConfig?
        var jsonlHandle: FileHandle?
    }

    private var sessions: [SessionID: SessionRecord] = [:]
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder

    public init() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.withoutEscapingSlashes]
        self.encoder = enc
    }

    // MARK: - ExportGateway

    public func beginSession(id: SessionID, config: TrainingExportConfig?) async throws {
        guard sessions[id] == nil else { return }

        let root = try sessionsRoot()
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")

        let folder = root.appendingPathComponent("session_\(timestamp)_\(id.rawValue.uuidString)",
                                                 isDirectory: true)
        try fileManager.createDirectory(at: folder,
                                        withIntermediateDirectories: true)

        // Create/open JSONL file if JSONL is enabled (or config is nil => default true).
        var handle: FileHandle?
        let shouldWriteJSONL = config?.enableJSONL ?? true
        if shouldWriteJSONL {
            let jsonlURL = folder.appendingPathComponent("frames.jsonl")
            if !fileManager.fileExists(atPath: jsonlURL.path) {
                fileManager.createFile(atPath: jsonlURL.path, contents: nil)
            }
            handle = try FileHandle(forWritingTo: jsonlURL)
            try handle?.seekToEnd()
        }

        let rec = SessionRecord(id: id, folder: folder, config: config, jsonlHandle: handle)
        sessions[id] = rec
    }

    public func endSession(id: SessionID) async {
        guard var rec = sessions[id] else { return }
        do {
            try rec.jsonlHandle?.close()
        } catch {
            // Swallow errors for now; you can add logging later.
        }
        sessions.removeValue(forKey: id)
    }

    public func exportFrame(id: SessionID, processed: ProcessedFrame) async {
        guard var rec = sessions[id] else { return }

        // JSONL export
        if let handle = rec.jsonlHandle {
            do {
                let data = try encoder.encode(processed)
                handle.write(data)
                if let newline = "\n".data(using: .utf8) {
                    handle.write(newline)
                }
            } catch {
                // TODO: optional dev logging
            }
        }

        // TODO: Later:
        // - If rec.config?.exportRAWStills == true, tie in still capture via another gateway.
        // - If you want .bin grids, add functions to write ScalarGrid / DepthGrid as binary.
        sessions[id] = rec
    }

    // MARK: - Helpers

    private func sessionsRoot() throws -> URL {
        guard let docs = fileManager.urls(for: .documentDirectory,
                                          in: .userDomainMask).first else {
            throw NSError(domain: "FileExportGateway", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No documents directory"])
        }
        let root = docs.appendingPathComponent("ChromaSessions", isDirectory: true)
        if !fileManager.fileExists(atPath: root.path) {
            try fileManager.createDirectory(at: root,
                                            withIntermediateDirectories: true)
        }
        return root
    }
}