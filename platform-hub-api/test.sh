#!/bin/sh

# Source local env variables for test execution
source .env.test

# Setup the environment
bin/setup

# Execute tests
bundle exec rspec
