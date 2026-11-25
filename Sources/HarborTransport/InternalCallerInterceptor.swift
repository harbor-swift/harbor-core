// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import GRPCCore
import GRPCNIOTransportHTTP2
public import Logging
import X509

/// Admits to each listed RPC only the processes whose certificates name one of its callers.
///
/// A caller is a DNS name in the peer certificate's subject alternative names, compared case-insensitively;
/// the common name is never read. A listed RPC refuses any other peer, or a call with no certificate, with
/// `permissionDenied`. An RPC the map doesn't list passes. Applied first, to every service of the server.
public struct InternalCallerInterceptor: ServerInterceptor {
    private let callers: [MethodDescriptor: Set<String>]
    private let logger: Logger

    /// - Parameters:
    ///   - callers: each internal RPC, and the identities of the processes that may call it.
    ///   - logger: where each refused call is logged, at `warning`.
    public init(callers: [MethodDescriptor: Set<String>], logger: Logger) {
        self.callers = callers.mapValues { Set($0.map { $0.lowercased() }) }
        self.logger = logger
    }

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next:
            @concurrent @Sendable (
                _ request: StreamingServerRequest<Input>,
                _ context: ServerContext
            ) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        guard let methodCallers = callers[context.descriptor] else {
            return try await next(request, context)
        }

        guard
            let transportContext = context.transportSpecific as? HTTP2ServerTransport.Posix.Context,
            let certificate = transportContext.peerCertificate,
            let subjectAlternativeNames = try certificate.extensions.subjectAlternativeNames
        else {
            logger.warning(
                "Internal call refused: no caller certificate",
                metadata: ["method": "\(context.descriptor)"]
            )
            throw RPCError(code: .permissionDenied, message: "The caller is not allowed.")
        }

        let dnsNames = subjectAlternativeNames.compactMap { name -> String? in
            guard case .dnsName(let dnsName) = name else {
                return nil
            }

            return dnsName.lowercased()
        }
        guard dnsNames.contains(where: methodCallers.contains) else {
            logger.warning("Internal call refused: caller not allowed", metadata: ["method": "\(context.descriptor)"])
            throw RPCError(code: .permissionDenied, message: "The caller is not allowed.")
        }

        return try await next(request, context)
    }
}
