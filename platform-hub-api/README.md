# Platform Hub API

_TODO:_
- Explain why we're binding the server on 0.0.0.0 when using `bin/rails server` locally (this is so we can bind to all adapters and thus allow access via the loopback alias from docker containers – needed for the auth proxy)
- Explain how to run tests (`bundle exec rspec`)
- Explain how to run server (`bin/rails server`)
- Explain how `.env` and `.env.local` works
- Explain the `./bin` folder and relevant scripts like `./bin/setup` and `./bin/update`
- Postgres:
  - `./bin/postgres/*` – a provided way to quickly run a Postgres container locally (but optional)
