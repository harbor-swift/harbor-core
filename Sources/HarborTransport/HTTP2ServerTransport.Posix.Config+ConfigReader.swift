public import Configuration
public import GRPCNIOTransportHTTP2

extension HTTP2ServerTransport.Posix.Config {
    /// Bounds each connection's age, so clients reconnect with renewed certificates, and its concurrent calls.
    ///
    /// ## Configuration keys
    /// - `maxConnectionAgeSeconds` (int, default 1800), `connectionGraceTimeSeconds` (int, default 30)
    /// - `minPingIntervalSeconds` (int, default 10): the shortest keepalive interval a client may use.
    /// - `maxConcurrentStreams` (int, default 100)
    public init(config: ConfigReader) {
        let maxConnectionAge = config.int(forKey: "maxConnectionAgeSeconds", as: Duration.self, default: .seconds(1800))
        let connectionGraceTime = config.int(
            forKey: "connectionGraceTimeSeconds",
            as: Duration.self,
            default: .seconds(30)
        )
        let minPingInterval = config.int(forKey: "minPingIntervalSeconds", as: Duration.self, default: .seconds(10))
        let maxConcurrentStreams = config.int(forKey: "maxConcurrentStreams", default: 100)

        self = .defaults
        self.connection.maxAge = maxConnectionAge
        self.connection.maxGraceTime = connectionGraceTime
        self.connection.keepalive.clientBehavior.minPingIntervalWithoutCalls = minPingInterval
        self.connection.keepalive.clientBehavior.allowWithoutCalls = true
        self.http2.maxConcurrentStreams = maxConcurrentStreams
    }
}
