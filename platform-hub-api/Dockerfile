FROM alpine:3.5

ENV RAILS_ENV production

RUN apk update && apk upgrade \
    && apk --update add ca-certificates libressl \
    && update-ca-certificates \
    && apk --update add \
    bash curl ruby ruby-irb ruby-rake ruby-io-console ruby-json ruby-bigdecimal libstdc++ tzdata \
    postgresql-client postgresql-dev \
    && apk --update add --virtual build_deps sudo build-base ruby-dev libc-dev libressl-dev zlib-dev \
    && echo 'gem: --no-document' > /etc/gemrc \
    && gem install bundler -v 2.1.0

# Create app user and directory, set permissions
WORKDIR /app
COPY . .
RUN addgroup -S app \
    && adduser -S -g app -u 1000 app \
    && chown -R app:app /app

# Install deps
RUN /bin/bash -c 'sudo -u app bundle install --jobs 20 --retry 5 --deployment --without development test --no-cache' && \
    apk del build_deps

ENV HOME /app
USER 1000

CMD ["bundle", "exec", "rails", "s"]
