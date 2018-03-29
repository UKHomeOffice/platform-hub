FROM alpine:3.5

ENV RAILS_ENV production

RUN apk update && apk upgrade \
    && apk --update add ca-certificates openssl \
    && update-ca-certificates \
    && apk --update add \
    bash curl ruby ruby-irb ruby-rake ruby-io-console ruby-json ruby-bigdecimal libstdc++ tzdata \
    postgresql-client \
    && echo 'gem: --no-document' > /etc/gemrc \
    && gem install bundler -v 1.16.0

# Create app user and directory, set permissions
WORKDIR /app
COPY . .
RUN addgroup -S app \
    && adduser -S -g app -u 1000 app \
    && chown -R app:app /app

# Install deps
RUN apk --update add --virtual build_deps sudo build-base ruby-dev libc-dev && \
    apk --update add postgresql-dev libxml2-dev libxslt-dev && \
    /bin/bash -c 'sudo -u app env NOKOGIRI_USE_SYSTEM_LIBRARIES=true bundle install --jobs 20 --retry 5 --deployment --without development test --no-cache' && \
    apk del build_deps

ENV HOME /app
USER 1000

CMD bundle exec rails s
