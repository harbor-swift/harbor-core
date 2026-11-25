// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

/// A role as the token names it, open so a role added later decodes everywhere.
public struct UserRole: RawRepresentable, Hashable, Codable, ExpressibleByStringLiteral, Sendable {
    public static let user: UserRole = "user"
    public static let admin: UserRole = "admin"

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
