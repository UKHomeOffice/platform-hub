# HODDAT PaaS Hub

[![Build Status](https://drone-external.digital.homeoffice.gov.uk/api/badges/UKHomeOffice/platform-hub/status.svg)](https://drone-external.digital.homeoffice.gov.uk/UKHomeOffice/platform-hub)

## General architecture

- The `platform-hub-web` web app is a standalone AngularJS 1.5 app that talks to the API via `/api`.
  - A dev server is provided for local development, which serves the static assets and proxies API calls to the backend.
- The `platform-hub-auth-proxy` folder provides scripts to manage a local [keycloak-proxy](https://github.com/gambol99/keycloak-proxy) in a container, which handles authentication for the API requests and proxies upstream to the API server when authenticated (or whitelisted).
- The `platform-hub-api` is a Ruby on Rails 5.0 API-only app to provide a mainly JSON based API and a backend for business logic and persistence, and for communicating with other backend and external services.
  - PostgreSQL is used as the only persistence store.


See the individual README files in the subfolders for details.
