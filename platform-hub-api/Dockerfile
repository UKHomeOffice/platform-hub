FROM ruby:2.3.3

RUN apt-get update && apt-get -u upgrade
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list.d/pgdg.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update && apt-get install -y libpq-dev

WORKDIR /app

ENV RAILS_ENV production
ENV RACK_ENV production

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 20 --retry 5 --deployment --without development test --no-cache

COPY . .

CMD ["bundle", "exec", "rails", "s"]
