public import Authentication
public import HarborAuthentication

/// Proves the tokens a test maps to identities, and refuses every other.
public struct MockAuthenticator: Authenticator {
    public struct InvalidToken: Error {}

    private let identities: [String: UserIdentity]

    public init(identities: [String: UserIdentity]) {
        self.identities = identities
    }

    public func authenticate(_ token: String) async throws -> UserIdentity {
        guard let identity = identities[token] else {
            throw InvalidToken()
        }

        return identity
    }
}
