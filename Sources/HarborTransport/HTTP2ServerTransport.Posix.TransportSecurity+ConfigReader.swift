// Copyright (c) 2026 Zaid Rahhawi
// SPDX-License-Identifier: MIT
// See LICENSE for license information.

public import Configuration
public import GRPCNIOTransportHTTP2
public import NIOCertificateReloading

extension HTTP2ServerTransport.Posix.TransportSecurity {
    /// Requires every peer to present a certificate the trust roots signed.
    ///
    /// ## Configuration keys
    /// - `trustRootsPath` (string, required): the PEM bundle of the authority that signs peers.
    public static func mTLS(config: ConfigReader, certificateReloader: any CertificateReloader) throws -> Self {
        let trustRootsPath = try config.requiredString(forKey: "trustRootsPath")
        return try .mTLS(certificateReloader: certificateReloader) {
            $0.trustRoots = .certificates([.file(path: trustRootsPath, format: .pem)])
            $0.clientCertificateVerification = .noHostnameVerification
        }
    }
}
