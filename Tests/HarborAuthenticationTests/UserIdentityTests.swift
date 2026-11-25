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
        let claims = try JSONSerialization.jsonObject(with: json) as? [String: Any]

        #expect(Set(claims?.keys ?? [:].keys) == ["sub", "role", "iss", "iat", "exp"])
        #expect(claims?["sub"] as? String == userID.uuidString.lowercased())
        #expect(claims?["role"] as? String == "user")
        #expect(claims?["iss"] as? String == "harbor-auth")
    }
}
