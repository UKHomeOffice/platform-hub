FROM alpine:3.14

ENV RAILS_ENV production

RUN apk update && apk upgrade \
    && apk --update add ca-certificates libressl \
    && update-ca-certificates \
    && apk --update add \
    bash curl ruby ruby-irb ruby-rake ruby-io-console ruby-json ruby-bigdecimal libstdc++ tzdata \
    postgresql-client postgresql-dev \
    && apk --update add --virtual build_deps sudo build-base ruby-dev libc-dev libressl-dev zlib-dev \
    && echo 'gem: --no-document' > /etc/gemrc \
    && gem install rdoc etc \
    && gem update --system \
    && gem install bundler -v 2.3.14 \
    && update-ca-certificates \
    && cp /etc/ssl/certs/ca-certificates.crt /etc/ssl/cert.pem

# Create app user and directory, set permissions
WORKDIR /app
COPY . .
RUN addgroup -S app \
    && adduser -S -g app -u 1000 app \
    && chown -R app:app /app

# Install deps
# RUN sudo -u app /bin/bash -c 'bundle config set --local deployment "true";  bundle config set --local without "development test"; bundle install --jobs 20 --retry 5 --no-cache' \
# RUN sudo -u app /bin/bash -c 'bundle config set --local deployment "true";  bundle config set --local without "development test"; bundle add etc' \
    # && apk del build_deps
RUN sudo -u app /bin/bash -c "bundle config set --local path 'vendor/bundle'; bundle add etc" \
    && apk del build_deps

ENV HOME /app
USER 1000

CMD ["bundle", "exec", "rails", "s"]
