// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import Authentication
public import Logging
import OperationContext

extension Logger.MetadataProvider {
    /// The bound user's id on every log line of a request; nothing when no user is bound.
    public static let user = Logger.MetadataProvider {
        guard let user = OperationContext.current.user else {
            return [:]
        }

        return ["userID": "\(user.identity.userID)"]
    }
}
