# Platform Hub – Local Auth Proxy

Uses [keycloak-proxy](https://github.com/gambol99/keycloak-proxy)

The `local` folder contains scripts to manage a local `keycloak-proxy` instance in a Docker container.

**Note:** if using a Mac, you'll need to use Docker for Mac v17.06+ (to allow easier container -> host network comms).

To get this working locally, you'll need to create/copy a `local/.env.local` file for the Keycloak access credentials and other security related config (automatically picked up by the script(s)). This file must export the following environment variables:
- `KCPROXY_CLIENT_ID`
- `KCPROXY_CLIENT_SECRET`
- `KCPROXY_ENCRYPTION_KEY` (must be either 16 or 32 characters)

Additionally, you can override the `KCPROXY_UPSTREAM_URL` in your local env file if you have a different setup.

## General workflow

Note: make sure you run scripts from the root of auth proxy.

- _Create_ the container for the first time
  - `local/create`
- _Stop_ the container when you don't need it
  - `local/stop`
- _Start_ the container when you do need it again
  - `local/start`
- _Destroy_ the container if you want to recreate it or just don't need it anymore
  - `local/destroy`
