// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import AuthenticationJWT
import Crypto
public import JWTKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension JWTIssuer {
    /// Signs with an Ed25519 private key, naming its `kid` in each token's header.
    ///
    /// The `kid` is the key's RFC 7638 thumbprint, which every verifier derives from the public key alone.
    public init(privateKey: EdDSA.PrivateKey) async {
        let kid = EdDSA.PublicKey.thumbprint(of: privateKey.publicKey)
        let keys = JWTKeyCollection()
        await keys.add(eddsa: privateKey, kid: kid)
        self.init(keys: keys, kid: kid)
    }
}

extension JWTAuthenticator {
    /// Verifies against Ed25519 public keys, each found by the `kid` a token names.
    ///
    /// No key is the collection's default, so a token that names no `kid`, or one none of these keys has, is
    /// refused before its signature is checked.
    public init(publicKeys: [EdDSA.PublicKey]) async throws {
        let keys = JWTKeyCollection()
        for publicKey in publicKeys {
            let kid = EdDSA.PublicKey.thumbprint(of: publicKey)
            let x = EdDSA.PublicKey.base64URL(publicKey.rawRepresentation)
            let jwk = JWK.octetKeyPair(.eddsa, identifier: kid, x: x, y: nil, curve: .ed25519)
            try await keys.add(jwk: jwk, isDefault: false)
        }
        self.init(keys: keys)
    }
}

extension EdDSA.PublicKey {
    /// The key's RFC 7638 JWK thumbprint: SHA-256 over its required members in lexicographic order.
    fileprivate static func thumbprint(of publicKey: EdDSA.PublicKey) -> JWKIdentifier {
        let x = base64URL(publicKey.rawRepresentation)
        let canonicalJWK = #"{"crv":"Ed25519","kty":"OKP","x":"\#(x)"}"#
        let digest = SHA256.hash(data: Array(canonicalJWK.utf8))
        let thumbprint = base64URL(Data(digest))
        return JWKIdentifier(string: thumbprint)
    }

    /// RFC 4648's base64url alphabet, without padding, as JOSE writes binary values.
    fileprivate static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
    }
}
