// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import HarborAuthentication
public import PersistencePostgres

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension PostgresSettings {
    /// The transaction-local settings that row-level security reads to find the caller.
    public static func user(_ identity: UserIdentity) -> PostgresSettings {
        ["app.caller_user_id": identity.userID.uuidString.lowercased()]
    }
}
