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

struct JWTAuthenticatorTests {
    private let privateKey: EdDSA.PrivateKey
    private let authenticator: JWTAuthenticator<UserIdentity>

    init() async throws {
        privateKey = try EdDSA.PrivateKey(curve: .ed25519)
        authenticator = try await JWTAuthenticator<UserIdentity>(publicKeys: [privateKey.publicKey])
    }

    private func identity(expiringIn lifetime: TimeInterval) -> UserIdentity {
        let issueDate = Date.now
        return UserIdentity(
            userID: UUID(),
            role: .user,
            issuer: "harbor-auth",
            issueDate: issueDate,
            expirationDate: issueDate.addingTimeInterval(lifetime)
        )
    }

    @Test("Accepts a token signed by either key while a key rotates")
    func acceptsBothKeysDuringRotation() async throws {
        let newPrivateKey = try EdDSA.PrivateKey(curve: .ed25519)
        let rotatingAuthenticator = try await JWTAuthenticator<UserIdentity>(
            publicKeys: [privateKey.publicKey, newPrivateKey.publicKey]
        )
        let oldIssuer = await JWTIssuer<UserIdentity>(privateKey: privateKey)
        let newIssuer = await JWTIssuer<UserIdentity>(privateKey: newPrivateKey)
        let identity = identity(expiringIn: 900)

        let oldToken = try await oldIssuer.issue(for: identity)
        let newToken = try await newIssuer.issue(for: identity)

        #expect(try await rotatingAuthenticator.authenticate(oldToken).userID == identity.userID)
        #expect(try await rotatingAuthenticator.authenticate(newToken).userID == identity.userID)
    }

    @Test("Refuses an expired token")
    func refusesExpiredToken() async throws {
        let issuer = await JWTIssuer<UserIdentity>(privateKey: privateKey)
        let token = try await issuer.issue(for: identity(expiringIn: -60))

        await #expect(throws: JWTError.self) {
            try await authenticator.authenticate(token)
        }
    }

    @Test("Refuses a token signed by a key it doesn't hold")
    func refusesUnknownKey() async throws {
        let otherPrivateKey = try EdDSA.PrivateKey(curve: .ed25519)
        let issuer = await JWTIssuer<UserIdentity>(privateKey: otherPrivateKey)
        let token = try await issuer.issue(for: identity(expiringIn: 900))

        await #expect(throws: JWTError.self) {
            try await authenticator.authenticate(token)
        }
    }

    @Test("Refuses a token that names no kid, even when its signature is good")
    func refusesTokenWithoutKeyIdentifier() async throws {
        let keys = JWTKeyCollection()
        await keys.add(eddsa: privateKey)
        let token = try await keys.sign(identity(expiringIn: 900))

        await #expect(throws: JWTError.self) {
            try await authenticator.authenticate(token)
        }
    }

    @Test("Refuses a token whose subject isn't a UUID")
    func refusesNonUUIDSubject() async throws {
        struct ForeignClaims: JWTPayload {
            let sub: String
            let role: String
            let iss: String
            let iat: Date
            let exp: Date

            func verify(using algorithm: some JWTAlgorithm) throws {}
        }

        let issuer = await JWTIssuer<ForeignClaims>(privateKey: privateKey)
        let claims = ForeignClaims(
            sub: "not-a-uuid",
            role: "user",
            iss: "harbor-auth",
            iat: .now,
            exp: Date.now.addingTimeInterval(900)
        )
        let token = try await issuer.issue(for: claims)

        await #expect(throws: (any Error).self) {
            try await authenticator.authenticate(token)
        }
    }
}
