// UseCases/HistoryUseCase.swift
// Loading and refreshing past sessions.

import Foundation
import ChromaDomain

public protocol HistoryUseCase: Sendable {
    /// Load the most recent sessions, up to the specified limit.
    func loadRecent(limit: Int) async -> [SessionSummary]
}

public actor HistoryInteractor: HistoryUseCase {
    private let history: HistoryGateway

    public init(history: HistoryGateway) {
        self.history = history
    }

    public func loadRecent(limit: Int) async -> [SessionSummary] {
        do {
            return try await history.loadRecentSessions(limit: limit)
        } catch {
            // In a stricter design, you'd forward this to an error reporting path.
            // For now, return an empty list on failure.
            return []
        }
    }
}
