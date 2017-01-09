# Platform Hub Auth Proxy

Uses [keycloak-proxy](https://github.com/gambol99/keycloak-proxy)

The `local` folder contains scripts to manage a local `keycloak-proxy` instance in a Docker container.

Note: you'll need to create/copy a `local/.env.local` file for the Keycloak access credentials and other security related config (automatically picked up by the script(s)). This file must export the following environment variables:
- `KCPROXY_CLIENT_ID`
- `KCPROXY_CLIENT_SECRET`
- `KCPROXY_ENCRYPTION_KEY` (must be either 16 or 32 characters)
