# ``HarborAuthentication``

Who the caller is: the claims Harbor's access tokens carry, and how they're signed and verified.

## Overview

Auth signs every access token with an Ed25519 private key, naming the key's `kid`; Users and the gateway
verify each token against the public key file. ``UserIdentity`` is the token's payload: a transport binds it
to the call's `OperationContext` as its user, and every log line written during the call carries it as
metadata.

## Topics

### The caller

- ``UserIdentity``
- ``UserRole``
