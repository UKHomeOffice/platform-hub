# Platform Hub – the software powering the Application Container Platform Hub at the UK Home Office

## Running the app

Run the below:
```sh
docker compose up -d
```

Visit http://host.docker.internal:3000/ to use the app.

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

----

[ACP] Tom Haynes
  9:43 AM
Hey Alastair, just to give you a few snippets these are the env variables I set
AGENT_KEYCLOAK_CLIENT_ID=platform-hub
AGENT_KEYCLOAK_CLIENT_SECRET=<same as the client secret in the proxy env>
AGENT_KEYCLOAK_USERNAME=platform-hub
AGENT_KEYCLOAK_PASSWORD=changeme
AGENT_KEYCLOAK_BASE_URL=https://sso-dev.notprod.homeoffice.gov.uk
AGENT_KEYCLOAK_REALM=hod-test
And heres a quick setup I did for the db, as mentioned all the containers in my docker compose run in host mode.
  cloudbeaver:
    container_name: cloudbeaver
    image: dbeaver/cloudbeaver
    volumes:
      - ./data/cloudbeaver:/opt/cloudbeaver/workspace
    network_mode: host

  platform-hub-db:
    container_name: platform-hub-db
    image: postgres:12.5
    environment:
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - pgdata:/var/lib/postgresql/data
    env_file:
      - ./platform-hub-api/bin/postgres/.env
    network_mode: host


Alastair Mottram-Epson
  9:45 AM
Perfect, thanks.
If you want, please push the change into feature/setup branch.
9:48
Does network_mode allow docker containers to interact with other docker containers via host.docker.internal rather than host.docker.internal?


[ACP] Tom Haynes
  9:49 AM
yep


Alastair Mottram-Epson
  9:49 AM
I wish I knew about that earlier :face_palm: .
:+1:
1










