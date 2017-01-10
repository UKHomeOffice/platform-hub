# Postgres container scripts

Scripts to run and interact with a local containerised Postgres.

Intended for local dev and not for production environments!

Uses a local data volume to store the pgdata.

See `env.sh` for details of the set up.

## Prequisites

- Docker 1.12.x
  - On Mac: [Docker for Mac](https://docs.docker.com/docker-for-mac/)

## General workflow

Note: make sure you run scripts from the root of your Rails app.

- _Create_ the container for the first time
  - `bin/postgres/create`
- Access an interactive [psql](http://postgresguide.com/utilities/psql.html) console into the running Postgres
  - `bin/postgres/console`
- _Stop_ the container when you don't need it
  - `bin/postgres/stop`
- _Start_ the container when you do need it again
  - `bin/postgres/start`
- _Destroy_ the container if you want to recreate it or just don't need it anymore (note: the local data volume will NOT be deleted)
  - `bin/postgres/destroy`
