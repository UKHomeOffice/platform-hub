# Platform Hub – the software powering the Application Container Platform Hub at the UK Home Office

## Wiki pages

Look at these confluence pages [ACP Platform Hub](https://collaboration.homeoffice.gov.uk/display/DSASS/ACP-Platform).

## Running the app

### Prerequisites

Follow these confluence pages for setting the environments for:
* [Keycloak proxy](https://collaboration.homeoffice.gov.uk/display/DSASS/ACP+Platform+Hub+-+keycloak+auth+proxy+local+setup).
* [Backend API](https://collaboration.homeoffice.gov.uk/display/DSASS/ACP+Platform+Hub+-+How+to+setup+API+backend+locally)

### How To

Run the below:
```sh
docker compose up -d
```

Visit http://host.docker.internal:3000/ to use the app.
- http://localhost:3000 will not work.

### Enabling All Feature

To try of the roles in the platform hub:
- admin
- limited_admin

Admin have access to the feature flag page, which allows them to determine what features are available for use in the app.
- This feature is required to test all feature in the app on the frontend.

Run the following in the database (platform-hub-db) to get the all the features in the app:
Access database:

```sh
psql -U $POSTGRES_USER -d $POSTGRES_DB
```

For admin users:
```sql
UPDATE users SET role = 'admin';
```

For limited_admin, try:
```sql
UPDATE users SET role = 'limited_admin';
```

**NOTE**: As of April 2nd 2024:
- This is a not an ideal since the role information is not documented.
- I don't know if there is better way to do this.
- However, the above works for providing the full range of features to test, so it has some use.

## General Architecture

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

## Versioning and release process

All services/components provided by this repo are currently versioned together using the same version identifier on every release, determined by Git tags and corresponding Docker image tags.

Creating and pushing a Git tag in this repo will trigger a drone pipeline that builds Docker images tagged with the same tag value, and pushes them to the relevant Quay.io repositories.

The general process to prepare a new release of Docker images:

- Switch to / pull the latest `master` branch (ensuring this has previously built successfully)
- Find the latest version using `git tag`
- Tag a new incremental version (either major, minor or patch)
  - e.g. `git tag -a v0.5.1 -m "v0.5.1"`
- Push tags using `git push --tags`

### To deploy the `acp-ops` instance:

```bash
$ export DRONE_SERVER=https://drone-gh.acp.homeoffice.gov.uk
$ export DRONE_TOKEN=xxxxxxxxxxx
$ drone build promote UKHomeOffice/kube-platform-hub <build-no> acp-ops
```
