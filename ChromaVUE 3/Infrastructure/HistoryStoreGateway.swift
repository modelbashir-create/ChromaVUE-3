//
//  HistoryStoreGateway.swift
//  ChromaVUE 3
//
//  Created by Mohamed Elbashir on 11/4/25.
//


// Infrastructure/HistoryStoreGateway.swift
// Concrete HistoryGateway – placeholder implementation.

import Foundation
import ChromaDomain

/// Simple placeholder HistoryGateway that currently returns an empty list.
///
/// Later, you can back this by Core Data, a sqlite DB, or JSON index files.
public actor HistoryStoreGateway: ChromaDomain.HistoryGateway {
    public init() {}

    public func loadRecentSessions(limit: Int) async throws -> [ChromaDomain.SessionSummary] {
        // TODO: Implement real persistence.
        // For now, return an empty list so history UI can compile.
        return []
    }
}
