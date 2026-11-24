public import Persistence

/// Runs each transaction's closure on the scope a test gives it, with no store behind it.
public struct MockDatabase<Scope: Sendable>: Database {
    private let scope: Scope

    public init(scope: Scope) {
        self.scope = scope
    }

    public func withTransaction<T: Sendable>(_ operation: (Scope) async throws -> T) async throws -> T {
        try await operation(scope)
    }
}
