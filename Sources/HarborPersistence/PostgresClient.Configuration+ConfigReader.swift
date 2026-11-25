// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import Configuration
import NIOSSL
public import PostgresNIO

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension PostgresClient.Configuration {
    /// A role's pool, logging in with the role's password over TLS whenever the server offers it.
    ///
    /// TLS is `prefer`, postgres-nio's default: a server that offers TLS must present a certificate the trust
    /// roots sign for `host`, and one that offers none is reached in plaintext. The role that migrates, `owner`,
    /// starts each connection with a lock timeout and no statement timeout; every other role with a statement
    /// timeout and an idle-in-transaction timeout.
    ///
    /// ## Configuration keys
    /// - `host` (string, required), `port` (int, required), `db` (string, required)
    /// - `tls.trustRootsPath` (string, required): the authority that signs the server's certificate.
    /// - `<role>.user` (string, required): the role to log in as.
    /// - `<role>.passwordPath` (string, required): the file holding the role's password, a secret.
    /// - `<role>.maximumConnections` (int, default 10)
    /// - `statementTimeoutSeconds` (int, default 5), `idleInTransactionTimeoutSeconds` (int, default 10),
    ///   `lockTimeoutSeconds` (int, default 5)
    public init(config: ConfigReader, role: String) throws {
        let host = try config.requiredString(forKey: "host")
        let port = try config.requiredInt(forKey: "port")
        let database = try config.requiredString(forKey: "db")
        let trustRootsPath = try config.requiredString(forKey: "tls.trustRootsPath")
        let roleConfig = config.scoped(to: ConfigKey(role))
        let username = try roleConfig.requiredString(forKey: "user")
        let passwordPath = try roleConfig.requiredString(forKey: "passwordPath")
        let maximumConnections = roleConfig.int(forKey: "maximumConnections", default: 10)
        let statementTimeout = config.int(forKey: "statementTimeoutSeconds", default: 5)
        let idleInTransactionTimeout = config.int(forKey: "idleInTransactionTimeoutSeconds", default: 10)
        let lockTimeout = config.int(forKey: "lockTimeoutSeconds", default: 5)

        // The password is the file's first line, so a trailing newline from an editor is no part of it.
        let passwordURL = URL(filePath: passwordPath)
        let passwordData = try Data(contentsOf: passwordURL)
        let passwordFile = String(decoding: passwordData, as: UTF8.self)
        let password = String(passwordFile.prefix { !$0.isNewline })

        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        tlsConfiguration.trustRoots = .file(trustRootsPath)
        tlsConfiguration.certificateVerification = .fullVerification

        self.init(
            host: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: .prefer(tlsConfiguration)
        )
        self.options.tlsServerName = host
        self.options.maximumConnections = maximumConnections
        if role == "owner" {
            // A migration waits this long for a table's lock, then runs as long as it needs.
            self.options.additionalStartupParameters = [("lock_timeout", "\(lockTimeout)s")]
        } else {
            self.options.additionalStartupParameters = [
                ("statement_timeout", "\(statementTimeout)s"),
                ("idle_in_transaction_session_timeout", "\(idleInTransactionTimeout)s"),
            ]
        }
    }
}
