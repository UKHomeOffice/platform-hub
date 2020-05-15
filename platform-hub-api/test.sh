#!/bin/sh

# Source local env variables for test execution
source .env.test

bin/rails db:migrate RAILS_ENV=test

# Setup the environment
bin/setup

# Execute tests
bundle exec rspec
