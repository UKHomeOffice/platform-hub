# Platform Hub – the software powering the HODDAT PaaS Hub

## General architecture

### `platform-hub-web`

[README](platform-hub-web/README.md)

[Source code](platform-hub-web) for the web app for users of the PaaS.

- Uses AngularJS 1.5 as the main framework
- Runs fully client side (served as static assets)
- Talks to the backend API via `/api` calls in the browser
- A local development and build stack is used for easy development, testing and building of the static assets

### `platform-hub-auth-proxy`

[README](platform-hub-auth-proxy/README.md)

[keycloak-proxy](https://github.com/gambol99/keycloak-proxy) sits in front of the API server and handles authentication using [Keycloak](http://www.keycloak.org/).

**All** `/api` requests go through this and keycloak-proxy takes care of proxying upstream to the API server when authenticated (or whitelisted).

[The folder in this repo](platform-hub-auth-proxy) only provides scripts to manage a **local** keycloak-proxy (in a container), not for production environments.

### `platform-hub-api`

[README](platform-hub-api/README.md)

[Source code](platform-hub-api) for the backend API server – handling most of the business logic and persistence for the hub, and communicating with other backend and external services.

- Provides a mainly JSON based API
- Uses [Ruby on Rails](http://rubyonrails.org/) 5.0 (in API-only mode)
- Authentication credentials are expected to be provided by the keycloak-proxy (where needed)
- Handles all the authorisation business logic

### [PostgreSQL](https://www.postgresql.org/)

… is used as the persistence store.

## Drone build

See [the pipeline](.drone.yml) for all the steps involved in the various build pipelines.
