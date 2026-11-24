import Authentication
import GRPCCore
import HarborAuthentication
import HarborPersistence
import OperationContext
import PersistencePostgres
import Synchronization
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Records the settings bound when the interceptor calls the next handler.
private final class SettingsRecorder: Sendable {
    private let settings = Mutex<PostgresSettings?>(nil)

    var recordedSettings: PostgresSettings? {
        settings.withLock { $0 }
    }

    func record() {
        let current = OperationContext.current.postgresSettings
        settings.withLock { $0 = current }
    }
}

@Suite("UserSettingsInterceptor")
struct UserSettingsInterceptorTests {
    private let request = StreamingServerRequest<String>(single: ServerRequest(metadata: [:], message: "request"))
    private let context = ServerContext(
        descriptor: MethodDescriptor(fullyQualifiedService: "test.Service", method: "Method"),
        remotePeer: "in-process",
        localPeer: "in-process",
        cancellation: ServerContext.RPCCancellationHandle()
    )

    @Test("Binds the caller's id for the request's transactions")
    func bindsBoundUser() async throws {
        let userID = UUID()
        let identity = UserIdentity(
            userID: userID,
            role: .user,
            issuer: "harbor-auth",
            issueDate: .now,
            expirationDate: Date.now.addingTimeInterval(900)
        )
        var operationContext = OperationContext()
        operationContext.user = Principal(identity: identity, credential: "token")
        let interceptor = UserSettingsInterceptor()

        let recorder = SettingsRecorder()

        try await OperationContext.withContext(operationContext) {
            _ = try await interceptor.intercept(request: request, context: context) { _, _ in
                recorder.record()
                return StreamingServerResponse<String>(single: ServerResponse(message: "response"))
            }
        }

        #expect(recorder.recordedSettings?["app.caller_user_id"] == userID.uuidString.lowercased())
    }

    @Test("Binds nothing when no user is bound")
    func bindsNothingWithoutUser() async throws {
        let interceptor = UserSettingsInterceptor()
        let recorder = SettingsRecorder()

        _ = try await interceptor.intercept(request: request, context: context) { _, _ in
            recorder.record()
            return StreamingServerResponse<String>(single: ServerResponse(message: "response"))
        }

        #expect(recorder.recordedSettings == nil)
    }
}
