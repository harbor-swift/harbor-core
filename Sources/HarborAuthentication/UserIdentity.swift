public import JWTKit

#if canImport(FoundationEssentials)
public import FoundationEssentials
#else
public import Foundation
#endif

/// Who a request acts for: the claims of the access token that Auth issues and every process verifies.
///
/// The token carries identity only. A use case reads anything else, such as a profile, from the service that
/// owns it.
public struct UserIdentity: JWTPayload, Equatable, Sendable {
    public let userID: UUID
    public let role: UserRole
    public let issuer: String
    public let issueDate: Date
    public let expirationDate: Date

    public init(userID: UUID, role: UserRole, issuer: String, issueDate: Date, expirationDate: Date) {
        self.userID = userID
        self.role = role
        self.issuer = issuer
        self.issueDate = issueDate
        self.expirationDate = expirationDate
    }

    private enum CodingKeys: String, CodingKey {
        case userID = "sub"
        case role
        case issuer = "iss"
        case issueDate = "iat"
        case expirationDate = "exp"
    }

    /// Writes `sub` lowercase, as every id on the wire is; `UUID`'s own encoding is uppercase.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID.uuidString.lowercased(), forKey: .userID)
        try container.encode(role, forKey: .role)
        try container.encode(issuer, forKey: .issuer)
        try container.encode(issueDate, forKey: .issueDate)
        try container.encode(expirationDate, forKey: .expirationDate)
    }

    /// Refuses an expired token. One issuer signs every token, so the expiry is the only claim to check.
    public func verify(using algorithm: some JWTAlgorithm) throws {
        let expiration = ExpirationClaim(value: expirationDate)
        try expiration.verifyNotExpired()
    }
}
