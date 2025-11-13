//
//  SessionSummary.swift
//  ChromaVUE 3
//
//  Created by Mohamed Elbashir on 11/4/25.
//


// Domain/HistoryModels.swift
// Domain-level models for session history.

import Foundation

/// Summary row for a past session, suitable for a history list UI.
public struct SessionSummary: Identifiable, Hashable, Codable, Sendable {
    public let id: SessionID
    public let startedAt: Date
    public let mode: SessionMode
    public let frameCount: Int

    public init(id: SessionID,
                startedAt: Date,
                mode: SessionMode,
                frameCount: Int) {
        self.id = id
        self.startedAt = startedAt
        self.mode = mode
        self.frameCount = frameCount
    }
}