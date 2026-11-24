import Crypto
import GRPCCore
import GRPCNIOTransportHTTP2
import HarborTransport
import Logging
import Testing
import X509

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

struct InternalCallerInterceptorTests {
    private let createUser = MethodDescriptor(
        fullyQualifiedService: "harbor.users.v1.UserInternalService",
        method: "CreateUser"
    )
    private let getUser = MethodDescriptor(fullyQualifiedService: "harbor.users.v1.UserService", method: "GetUser")
    private let interceptor: InternalCallerInterceptor

    init() {
        let callers = [createUser: Set(["auth-worker"])]
        interceptor = InternalCallerInterceptor(callers: callers, logger: Logger(label: "test"))
    }

    /// A self-signed certificate whose common name and DNS names are the ones a test gives it.
    private func certificate(commonName: String, dnsNames: [String]) throws -> Certificate {
        let privateKey = P256.Signing.PrivateKey()
        let name = try DistinguishedName {
            CommonName(commonName)
        }
        let subjectAlternativeNames = SubjectAlternativeNames(dnsNames.map { GeneralName.dnsName($0) })
        let extensions = try Certificate.Extensions {
            subjectAlternativeNames
        }
        return try Certificate(
            version: .v3,
            serialNumber: Certificate.SerialNumber(),
            publicKey: Certificate.PublicKey(privateKey.publicKey),
            notValidBefore: Date.now.addingTimeInterval(-60),
            notValidAfter: Date.now.addingTimeInterval(3600),
            issuer: name,
            subject: name,
            signatureAlgorithm: .ecdsaWithSHA256,
            extensions: extensions,
            issuerPrivateKey: Certificate.PrivateKey(privateKey)
        )
    }

    private func context(for descriptor: MethodDescriptor, peerCertificate: Certificate?) -> ServerContext {
        var transportContext = HTTP2ServerTransport.Posix.Context()
        transportContext.peerCertificate = peerCertificate
        var context = ServerContext(
            descriptor: descriptor,
            remotePeer: "ipv4:127.0.0.1:50000",
            localPeer: "ipv4:127.0.0.1:50052",
            cancellation: ServerContext.RPCCancellationHandle()
        )
        context.transportSpecific = transportContext
        return context
    }

    private func intercept(_ context: ServerContext) async throws -> StreamingServerResponse<String> {
        let request = StreamingServerRequest<String>(single: ServerRequest(metadata: [:], message: "request"))
        return try await interceptor.intercept(request: request, context: context) { _, _ in
            StreamingServerResponse<String>(single: ServerResponse(message: "response"))
        }
    }

    @Test("Admits a listed RPC's caller by a DNS name, whatever its case", arguments: ["auth-worker", "Auth-Worker"])
    func admitsCallerByDNSName(dnsName: String) async throws {
        let certificate = try certificate(commonName: "anything", dnsNames: ["localhost", dnsName])
        let context = context(for: createUser, peerCertificate: certificate)

        let response = try await intercept(context)

        #expect(response.accepted.isSuccess)
    }

    @Test("Refuses a peer that names another process")
    func refusesAnotherCaller() async throws {
        let certificate = try certificate(commonName: "auth", dnsNames: ["auth"])
        let context = context(for: createUser, peerCertificate: certificate)

        let error = await #expect(throws: RPCError.self) {
            try await intercept(context)
        }

        #expect(error?.code == .permissionDenied)
    }

    @Test("Refuses a certificate that names the caller only as its common name")
    func refusesCallerNamedOnlyByCommonName() async throws {
        let certificate = try certificate(commonName: "auth-worker", dnsNames: ["auth"])
        let context = context(for: createUser, peerCertificate: certificate)

        let error = await #expect(throws: RPCError.self) {
            try await intercept(context)
        }

        #expect(error?.code == .permissionDenied)
    }

    @Test("Refuses a call to a listed RPC that presents no certificate")
    func refusesCallWithoutCertificate() async throws {
        let context = context(for: createUser, peerCertificate: nil)

        let error = await #expect(throws: RPCError.self) {
            try await intercept(context)
        }

        #expect(error?.code == .permissionDenied)
    }

    @Test("Passes an RPC the map doesn't list, with or without a certificate")
    func passesUnlistedRPC() async throws {
        let context = context(for: getUser, peerCertificate: nil)

        let response = try await intercept(context)

        #expect(response.accepted.isSuccess)
    }
}

extension Result {
    fileprivate var isSuccess: Bool {
        guard case .success = self else {
            return false
        }

        return true
    }
}
