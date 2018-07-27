# ElasticSearch container scripts

Scripts to run and interact with a local containerised ElasticSearch instance.

Intended for local dev and not for production environments!

Uses a local data volume to store the data.

See `.env` for details of the set up.

## Prerequisites

- Docker 1.12.x
  - On Mac: [Docker for Mac](https://docs.docker.com/docker-for-mac/)

## General workflow

Note: make sure you run scripts from the root of your Rails app.

- _Create_ the container for the first time
  - `bin/elasticsearch/create`
- _Stop_ the container when you don't need it
  - `bin/elasticsearch/stop`
- _Start_ the container when you do need it again
  - `bin/elasticsearch/start`
- _Destroy_ the container if you want to recreate it or just don't need it anymore (note: the local data volume will NOT be deleted)
  - `bin/elasticsearch/destroy`

Run `curl http://127.0.0.1:9200/_cat/health` to check status.
