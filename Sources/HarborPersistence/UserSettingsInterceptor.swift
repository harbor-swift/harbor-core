import Authentication
public import GRPCCore
import HarborAuthentication
import OperationContext
import PersistencePostgres

/// Binds the caller that the bearer interceptor proved to every transaction the request opens.
///
/// Applied after `BearerAuthenticationInterceptor`, to the same descriptors. With no user bound it binds
/// nothing, so a tenant policy matches no row.
public struct UserSettingsInterceptor: ServerInterceptor {
    public init() {}

    public func intercept<Input: Sendable, Output: Sendable>(
        request: StreamingServerRequest<Input>,
        context: ServerContext,
        next:
            @concurrent @Sendable (
                _ request: StreamingServerRequest<Input>,
                _ context: ServerContext
            ) async throws -> StreamingServerResponse<Output>
    ) async throws -> StreamingServerResponse<Output> {
        guard let user = OperationContext.current.user else {
            return try await next(request, context)
        }

        var operationContext = OperationContext.current
        operationContext.postgresSettings = .user(user.identity)
        return try await OperationContext.withContext(operationContext) {
            try await next(request, context)
        }
    }
}
