FROM ruby:2.3.8

WORKDIR /platform-hub-api
COPY . .

RUN gem install bundler -v 2.3.27
RUN bundle

RUN apk update && apk upgrade \
    && apk --update add ca-certificates libressl \
    && update-ca-certificates \
    && apk --update add \
    bash curl libstdc++ tzdata \
    postgresql-client postgresql-dev \
    && apk --update add --virtual build_deps sudo build-base ruby-dev libc-dev libressl-dev zlib-dev \
    && echo 'gem: --no-document' > /etc/gemrc \
    && gem update --system \
    && rm /etc/ssl/certs/ca-cert-DST_ACES_CA_X6.pem \
    && rm /etc/ssl/certs/ca-cert-DST_Root_CA_X3.pem \
    && update-ca-certificates \
    && cp /etc/ssl/certs/ca-certificates.crt /etc/ssl/cert.pem

RUN bin/rails db:setup


CMD [ "bin/rails", "server" ]