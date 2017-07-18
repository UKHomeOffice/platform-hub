FROM alpine:3.5

ENV RAILS_ENV production

RUN apk update && apk upgrade \
    && apk --update add ca-certificates openssl \
    && update-ca-certificates \
    && apk --update add \
    ruby ruby-dev ruby-io-console ruby-json ruby-bigdecimal tzdata \
    postgresql-client postgresql-dev build-base libxml2-dev libxslt-dev \
    && echo 'gem: --no-document' > /etc/gemrc \
    && gem install bundler

# Create app user and directory, set permissions
WORKDIR /app
COPY . .
RUN addgroup -S app \
    && adduser -S -g app app \
    && chown -R app:app /app
USER app
ENV HOME /app

# Install deps, start server
RUN bundle install --jobs 20 --retry 5 --deployment --without development test --no-cache
CMD bundle exec rails s
