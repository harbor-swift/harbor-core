public import Configuration
public import GRPCNIOTransportHTTP2
public import NIOCertificateReloading

extension HTTP2ClientTransport.Posix.TransportSecurity {
    /// Presents the process's certificate and verifies the server's chain and hostname in full.
    ///
    /// ## Configuration keys
    /// - `trustRootsPath` (string, required): the PEM bundle of the authority that signs servers.
    public static func mTLS(config: ConfigReader, certificateReloader: any CertificateReloader) throws -> Self {
        let trustRootsPath = try config.requiredString(forKey: "trustRootsPath")
        return try .mTLS(certificateReloader: certificateReloader) {
            $0.trustRoots = .certificates([.file(path: trustRootsPath, format: .pem)])
            $0.serverCertificateVerification = .fullVerification
        }
    }
}
