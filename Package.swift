// swift-tools-version: 6.4

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .strictMemorySafety(),
]

let package = Package(
    name: "harbor-core",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "HarborAuthentication", targets: ["HarborAuthentication"]),
        .library(name: "HarborPersistence", targets: ["HarborPersistence"]),
        .library(name: "HarborTransport", targets: ["HarborTransport"]),
        .library(name: "HarborTesting", targets: ["HarborTesting"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-microservices/swift-authentication.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-microservices/swift-authentication-jwt.git", from: "1.1.0"),
        .package(url: "https://github.com/swift-microservices/swift-operation-context.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-microservices/swift-persistence.git", from: "1.0.0"),
        .package(url: "https://github.com/swift-microservices/swift-persistence-postgres.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-certificates.git", from: "1.21.2"),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.5.0", traits: []),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "5.1.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.17.2"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.35.3"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.37.7"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.4.4"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.13.2"),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.9.1"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.33.3"),
    ],
    targets: [
        .target(
            name: "HarborAuthentication",
            dependencies: [
                .product(name: "Authentication", package: "swift-authentication"),
                .product(name: "AuthenticationJWT", package: "swift-authentication-jwt"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "OperationContext", package: "swift-operation-context"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "HarborPersistence",
            dependencies: [
                "HarborAuthentication",
                .product(name: "Authentication", package: "swift-authentication"),
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "OperationContext", package: "swift-operation-context"),
                .product(name: "PersistencePostgres", package: "swift-persistence-postgres"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "HarborTransport",
            dependencies: [
                "HarborAuthentication",
                .product(name: "AuthenticationJWT", package: "swift-authentication-jwt"),
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCertificateReloading", package: "swift-nio-extras"),
                .product(name: "X509", package: "swift-certificates"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "HarborTesting",
            dependencies: [
                "HarborAuthentication",
                .product(name: "Authentication", package: "swift-authentication"),
                .product(name: "Persistence", package: "swift-persistence"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "HarborAuthenticationTests",
            dependencies: [
                "HarborAuthentication",
                .product(name: "Authentication", package: "swift-authentication"),
                .product(name: "AuthenticationJWT", package: "swift-authentication-jwt"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "OperationContext", package: "swift-operation-context"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "HarborPersistenceTests",
            dependencies: [
                "HarborAuthentication",
                "HarborPersistence",
                .product(name: "Authentication", package: "swift-authentication"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "OperationContext", package: "swift-operation-context"),
                .product(name: "PersistencePostgres", package: "swift-persistence-postgres"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "HarborTransportTests",
            dependencies: [
                "HarborTransport",
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "X509", package: "swift-certificates"),
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
