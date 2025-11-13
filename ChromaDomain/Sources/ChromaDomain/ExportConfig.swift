// Domain/ExportConfig.swift
// Training / export configuration (domain-level).

import Foundation

/// Configuration describing what should be exported for a session.
/// For clinical mode this may be nil; for training we usually enable everything.
public struct TrainingExportConfig: Hashable, Codable, Sendable {
    public let enableJSONL: Bool
    public let enableBinGrids: Bool
    public let exportRAWStills: Bool
    public let exportHEICStills: Bool

    public init(
        enableJSONL: Bool,
        enableBinGrids: Bool,
        exportRAWStills: Bool,
        exportHEICStills: Bool
    ) {
        self.enableJSONL = enableJSONL
        self.enableBinGrids = enableBinGrids
        self.exportRAWStills = exportRAWStills
        self.exportHEICStills = exportHEICStills
    }

    /// Default training configuration: export everything.
    public static let trainingDefaults = TrainingExportConfig(
        enableJSONL: true,
        enableBinGrids: true,
        exportRAWStills: true,
        exportHEICStills: true
    )
}
