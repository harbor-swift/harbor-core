// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import HarborAuthentication
import JWTKit
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct UserIdentityTests {
    /// A claim's value, as JSON writes it.
    private enum Claim: Decodable, Equatable {
        case string(String)
        case number(Double)

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            do {
                self = .string(try container.decode(String.self))
            } catch DecodingError.typeMismatch {
                self = .number(try container.decode(Double.self))
            }
        }
    }

    private let userID = UUID(uuidString: "0193A1B2-C3D4-7E5F-8A9B-0C1D2E3F4A5B")!

    private func identity(expiringIn lifetime: TimeInterval) -> UserIdentity {
        let issueDate = Date.now
        return UserIdentity(
            userID: userID,
            role: .user,
            issuer: "harbor-auth",
            issueDate: issueDate,
            expirationDate: issueDate.addingTimeInterval(lifetime)
        )
    }

    @Test("Writes exactly the claims the system relies on, with a lowercase subject")
    func encodesClaims() throws {
        let identity = identity(expiringIn: 900)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let json = try encoder.encode(identity)
        let claims = try JSONDecoder().decode([String: Claim].self, from: json)

        #expect(Set(claims.keys) == ["sub", "role", "iss", "iat", "exp"])
        #expect(claims["sub"] == .string(userID.uuidString.lowercased()))
        #expect(claims["role"] == .string("user"))
        #expect(claims["iss"] == .string("harbor-auth"))
    }
}
