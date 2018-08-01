# Platform Hub – API Server & Backend

## Tech summary

A [Ruby on Rails](http://rubyonrails.org/) 5.0 API-only stack to provide a mainly JSON based API and backend for business logic and persistence, and for communicating with other backend and external services. Using [PostgreSQL](https://www.postgresql.org/) for persistence of data.

## Dev

### Prerequisites

#### Ruby v2.3.7

If you're using [RVM](https://rvm.io/) or some other Ruby manager, it may pick up the `.ruby-version` file automatically and use / set up the correct version of Ruby for you. If not, you'll need to install Ruby v2.3.7.

#### Package Dependencies

The following packages are required to run the API (may vary across Operating Systems):

* [Ruby v2.3.7](https://www.ruby-lang.org/en/). If you're using [RVM](https://rvm.io/) or some other Ruby manager, it may pick up the `.ruby-version` file automatically and use / set up the correct version of Ruby for you. If not, you'll need to install Ruby v2.3.7 or above (included in the below list).
* Developer Packages:
  * Debian/Ubuntu: `sudo apt-get install ruby ruby-dev postgresql-client libpq-dev`
  * Fedora/CentOS: `sudo yum install rubygems ruby-devel postgresql-client postgresql-devel`
  * OSX: `brew install ruby ruby-build postgresql`

#### Bundler

[Bundler](http://bundler.io/) is used for dependency management. Install this with `gem install bundler`.

#### PostgresSQL v9.6.1

For local development, we recommend using the scripts provided in `./bin/postgres/*` to easily manage a locally running PostgreSQL container with the correct config set up already. See the [relevant README doc](bin/postgres/README.md) for more details.

#### ElasticSearch v5.5.1

For local development, we recommend using the scripts provided in `./bin/elasticsearch/*` to easily manage a locally running ElasticSearch container with the correct config set up already. See the [relevant README doc](bin/elasticsearch/README.md) for more details.

### Dev flows

#### Set up local config

All config is passed as environment variables. The [`.env`](.env) file provided is loaded automatically by the Rails environment and contains some config options for an "out-of-the-box" developer experience (note: this file is committed to the Git repo).

You can override any config value by adding it to a `.env.local` file that you will need to create (this won't and shouldn't get committed to the Git repo). **You must have certain secret values set up in this `.env.local` file to make things work locally.** You may need to ask a fellow developer for some of these values. The following are the variables that need to be set in this file:
- `SECRET_KEY_BASE` – a string used for encryption. Usually 128 bytes.
- `GITHUB_CLIENT_ID` – the client ID for the GitHub OAuth app used for the identity connection. Make sure this is a test one and not a production one!
- `GITHUB_CLIENT_SECRET` – the client secret for the GitHub OAuth app used for the identity connection. Make sure this is a test one and not a production one!
- `AGENT_GITHUB_TOKEN` – the access token used for GitHub onboarding flows. This token MUST be for a user that has owner access to the GitHub organisation specified below.
- `AGENT_GITHUB_ORG` – the GitHub organisation that users will be onboarded on to.
- `AGENT_GITHUB_ORG_MAIN_TEAM_ID` – the integer ID of the GitHub team that users will be onboarded on to.
- `AGENT_KEYCLOAK_CLIENT_ID` - Keycloak client ID. Make sure this is a test one and not a production one!
- `AGENT_KEYCLOAK_CLIENT_SECRET` - Keycloak client secret. Make sure this is a test one and not a production one!
- `AGENT_KEYCLOAK_USERNAME` - Keycloak agent username. This is a Keycloak user with sufficient privileges to manage users in AGENT_KEYCLOAK_REALM.
- `AGENT_KEYCLOAK_PASSWORD` - Keycloak agent password.
- `AGENT_KEYCLOAK_BASE_URL` - Keycloak base URL. Make sure this is not a production Keycloak URL!
- `AGENT_KEYCLOAK_REALM` - The Keycloak realm in which users will be managed.
- `SLACK_WEBHOOK` – the webhook URL for Slack integration – use wisely when developing locally, just in case unwanted messages get sent to a public Slack channel – set to `noop` or some other string to ensure nothing gets sent out.

Note that these env files only work for local development and testing.

#### Install dependencies

```bash
bundle
```

#### Set up your local db

```bash
bin/rails db:setup
```

This will also set up your local tests database used when running the test suite.

#### Common tasks

- `bin/rails server` – runs a local server to serve the API (`Ctrl+C` to stop)
- `bin/rails jobs:work` – runs a non-daemonised [delayed_job](https://github.com/collectiveidea/delayed_job) worker to process background jobs (`Ctrl+C` to stop)
- `bundle exec rspec` – runs the tests (specified in the `/spec` folder)
- `bin/rails console` – runs a local Rails console to access your app
- `bin/rails db:migrate` – runs database migrations to get your local database to the latest schema

See the [Rails CLI guide](http://guides.rubyonrails.org/command_line.html) for details on many more useful command line tasks, for managing migrations, generating files, etc.

### General architectural points of interest

- As much as possible, we try to break out coherent, well isolated and single responsibility tasks/logic into "services" in the `app/services` folder.
- The services in `app/services/agents/*` are intended to provide "root" access to external services like GitHub, and thus should be used cautiously and be well tested wherever used!

### Announcements delivery

Announcements that need delivering (email, Slack, etc.) are processed in a background job (using [delayed_job](https://github.com/collectiveidea/delayed_job)). The processor job itself needs to be manually triggered using the following (this allows us to run it on a schedule):

```bash
bin/rails announcements:trigger_processor_job
```

… this puts a job on the queue. To work through the jobs in the queue, start up a worker:

```bash
bin/rails jobs:work
```

#### Slack delivery

As long as you have a valid `SLACK_WEBHOOK` set in your `.env.local` (or passed in through your environment), delivery of announcements to Slack channels will work. **Be careful when using this in local development though – only send to Slack channels that are okay to receive test messsages**.

#### Email delivery

To set up local email delivery, ensure you have the following env variables set (either in `.env.local` or passed through your environment):

- `EMAIL_SMTP_ADDRESS`
- `EMAIL_SMTP_PORT`
- `EMAIL_SMTP_USERNAME`
- `EMAIL_SMTP_PASSWORD`

**As usual, be careful when sending out emails from your local development environment!**

### Help search

The help search feature uses ElasticSearch; most of the relevant functionality is in the `HelpSearchService` class. The global instance `HelpSearchService.instance` can be used.

To reindex all help items from scratch to a fresh index:

```ruby
HelpSearchService.instance.reindex_all force: true
```

To reindex all help items into an existing index:

```ruby
HelpSearchService.instance.reindex_all
```

### Troubleshooting

#### Test database issues

If you experience issues with your tests starting up due to a database error (e.g. a `ActiveRecord::NoEnvironmentInSchemaError` that often occurs after migrating to a newer schema), then recreate the whole test db with:

```bash
bin/postgres/console -c "drop database phub_test"
bundle exec rake db:setup
```

Note: make sure your development db is fully up to date before running this (i.e. make sure all migrations have run, with `bin/rails db:migrate`) so that the test db has the latest schema.
