// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import Configuration
public import GRPCNIOTransportHTTP2

extension HTTP2ClientTransport.Posix.Config {
    /// Sends keepalive pings on idle connections, so a dead peer is noticed before a call needs it.
    ///
    /// ## Configuration keys
    /// - `keepaliveTimeSeconds` (int, default 30), `keepaliveTimeoutSeconds` (int, default 10)
    public init(config: ConfigReader) {
        let keepaliveTime = config.int(forKey: "keepaliveTimeSeconds", as: Duration.self, default: .seconds(30))
        let keepaliveTimeout = config.int(forKey: "keepaliveTimeoutSeconds", as: Duration.self, default: .seconds(10))

        self = .defaults
        self.connection.keepalive = HTTP2ClientTransport.Config.Keepalive(
            time: keepaliveTime,
            timeout: keepaliveTimeout,
            allowWithoutCalls: true
        )
    }
}
