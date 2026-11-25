// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

import Authentication
import HarborAuthentication
import Logging
import OperationContext
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("Logger.MetadataProvider.user")
struct UserMetadataProviderTests {
    @Test("Adds the bound user's id")
    func addsUserID() {
        let userID = UUID()
        let identity = UserIdentity(
            userID: userID,
            role: .user,
            issuer: "harbor-auth",
            issueDate: .now,
            expirationDate: Date.now.addingTimeInterval(900)
        )
        var context = OperationContext()
        context.user = Principal(identity: identity, credential: "token")

        let metadata = OperationContext.withContext(context) {
            Logger.MetadataProvider.user.get()
        }

        #expect(metadata["userID"] == "\(userID)")
    }

    @Test("Adds nothing when no user is bound")
    func addsNothingWithoutUser() {
        let metadata = Logger.MetadataProvider.user.get()

        #expect(metadata.isEmpty)
    }
}
