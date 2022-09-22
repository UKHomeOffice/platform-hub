FROM ruby:2.7.6-alpine3.16

ENV RAILS_ENV production

# Create app user and directory, set permissions
WORKDIR /app
COPY . .
RUN addgroup -S app \
    && adduser -S -g app -u 1000 app \
    && chown -R app:app /app

RUN apk update \
    && apk upgrade \
    && apk add ca-certificates ruby build-base postgresql-dev \ 
    && update-ca-certificates

USER app

RUN gem install 'bundler:2.3.14' etc \
    && bundle config set --local deployment "true" \
    && bundle config set --local without "development test" \
    && bundle install --jobs 20 --retry 5 --no-cache

ENV HOME /app

CMD ["bundle", "exec", "rails", "s"]
