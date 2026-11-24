public import Configuration
public import NIOCertificateReloading

extension TimedCertificateReloader.Configuration {
    /// The process's certificate and key, reloaded from disk as the deployment renews them.
    ///
    /// The root sets the configuration's `logger` and its `onCertificateLoadFailed`.
    ///
    /// ## Configuration keys
    /// - `certificatePath`, `privateKeyPath` (string, required): the PEM pair.
    /// - `refreshIntervalSeconds` (int, default 60): how often the files are read.
    public init(config: ConfigReader) throws {
        let certificatePath = try config.requiredString(forKey: "certificatePath")
        let privateKeyPath = try config.requiredString(forKey: "privateKeyPath")
        let refreshInterval = config.int(forKey: "refreshIntervalSeconds", as: Duration.self, default: .seconds(60))
        let certificateSource = TimedCertificateReloader.CertificateSource(
            location: .file(path: certificatePath),
            format: .pem
        )
        let privateKeySource = TimedCertificateReloader.PrivateKeySource(
            location: .file(path: privateKeyPath),
            format: .pem
        )
        self.init(
            refreshInterval: refreshInterval,
            certificateSource: certificateSource,
            privateKeySource: privateKeySource
        )
    }
}
