# ``HarborTransport``

Mutual TLS, HTTP/2 transports and token verification read from configuration, and the interceptor that admits
internal callers.

## Overview

Every gRPC hop in Harbor is mutual TLS against the environment's certificate authority, with certificates
reloaded from their files as they're renewed. Each process's certificate names it as a DNS name, and
``InternalCallerInterceptor`` admits an internal RPC's caller only when its certificate names one of the
callers listed for that RPC.

## Topics

### Internal callers

- ``InternalCallerInterceptor``
