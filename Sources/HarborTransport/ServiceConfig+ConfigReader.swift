// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import Configuration
public import GRPCCore

extension ServiceConfig {
    /// A deadline on every call, waiting for a ready connection within it, balanced across every replica.
    ///
    /// No retries or hedging: Temporal retries activities, and clients retry public creates with their keys.
    ///
    /// ## Configuration keys
    /// - `deadlineSeconds` (int, default 10)
    public init(config: ConfigReader) {
        let deadline = config.int(forKey: "deadlineSeconds", as: Duration.self, default: .seconds(10))
        let allMethods = MethodConfig.Name(service: "")
        let methodConfig = MethodConfig(names: [allMethods], waitForReady: true, timeout: deadline)
        self.init(methodConfig: [methodConfig], loadBalancingConfig: [.roundRobin])
    }
}
