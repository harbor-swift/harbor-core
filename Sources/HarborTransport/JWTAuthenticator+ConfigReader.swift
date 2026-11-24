public import AuthenticationJWT
public import Configuration
import HarborAuthentication
import JWTKit

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension JWTAuthenticator {
    /// Verifies tokens against every Ed25519 public key in the file at `publicKeyPath`.
    ///
    /// The file holds one PEM public key, or two while a key rotates. It's read once, at startup: a changed key
    /// reaches the process with its next deploy.
    ///
    /// ## Configuration keys
    /// - `publicKeyPath` (string, required): the PEM file of the public keys that verify access tokens.
    public init(config: ConfigReader) async throws {
        let publicKeyPath = try config.requiredString(forKey: "publicKeyPath")
        let publicKeyURL = URL(filePath: publicKeyPath)
        let publicKeyData = try Data(contentsOf: publicKeyURL)
        let publicKeyFile = String(decoding: publicKeyData, as: UTF8.self)

        var publicKeys: [EdDSA.PublicKey] = []
        var pemLines: [Substring] = []
        for line in publicKeyFile.split(whereSeparator: \.isNewline) {
            pemLines.append(line)
            if line.hasPrefix("-----END") {
                let pem = pemLines.joined(separator: "\n")
                let publicKey = try EdDSA.PublicKey(pem: pem)
                publicKeys.append(publicKey)
                pemLines = []
            }
        }
        guard !publicKeys.isEmpty else {
            throw JWTError.generic(identifier: "publicKeyPath", reason: "The file holds no PEM public key.")
        }

        try await self.init(publicKeys: publicKeys)
    }
}
