# ``HarborPersistence``

Postgres connections for each database role, and the caller bound to each transaction for row-level security.

## Overview

Each role's `PostgresClient` is configured from a `ConfigReader`, with its password read from a file and its
pool and timeouts bounded by configuration. ``UserSettingsInterceptor`` binds the verified caller to the call,
so every transaction a use case opens sets the user its row-level security policies read.

## Topics

### Binding the caller

- ``UserSettingsInterceptor``
