// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import AuthenticationJWT
import HarborAuthentication
import JWTKit
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct JWTIssuerTests {
    /// RFC 8037's Ed25519 example key (appendix A.1), whose RFC 7638 thumbprint is appendix A.3's.
    private let privateKey: EdDSA.PrivateKey
    private let expectedKeyIdentifier = "kPrK_qmxVWaYVA9wwBF6Iuo3vVzz7TxHCTwXBygrS4k"

    init() throws {
        privateKey = try EdDSA.PrivateKey(d: "nWGxne_9WmC6hEr0kuwsxERJxWl7MmkZcDusAxyuf2A", curve: .ed25519)
    }

    private func identity() -> UserIdentity {
        let issueDate = Date(timeIntervalSince1970: Date.now.timeIntervalSince1970.rounded(.down))
        return UserIdentity(
            userID: UUID(),
            role: .user,
            issuer: "harbor-auth",
            issueDate: issueDate,
            expirationDate: issueDate.addingTimeInterval(900)
        )
    }

    @Test("Names the key's RFC 7638 thumbprint as the kid in each token's header")
    func namesThumbprintAsKeyIdentifier() async throws {
        let issuer = await JWTIssuer<UserIdentity>(privateKey: privateKey)

        let token = try await issuer.issue(for: identity())

        let header = try #require(token.split(separator: ".").first)
        let base64 = String(header).replacing("-", with: "+").replacing("_", with: "/")
        let padding = String(repeating: "=", count: (4 - base64.count % 4) % 4)
        let headerJSON = try #require(Data(base64Encoded: base64 + padding))
        let headerFields = try JSONDecoder().decode([String: String].self, from: headerJSON)
        #expect(headerFields["kid"] == expectedKeyIdentifier)
        #expect(headerFields["alg"] == "EdDSA")
    }

    @Test("A token it issues verifies back to the same identity through the public key")
    func roundTrip() async throws {
        let issuer = await JWTIssuer<UserIdentity>(privateKey: privateKey)
        let authenticator = try await JWTAuthenticator<UserIdentity>(publicKeys: [privateKey.publicKey])
        let identity = identity()

        let token = try await issuer.issue(for: identity)
        let verifiedIdentity = try await authenticator.authenticate(token)

        #expect(verifiedIdentity == identity)
    }
}
