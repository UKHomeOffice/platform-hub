FROM ruby:2.3.8-alpine3.8

WORKDIR /platform-hub-api
COPY . .

RUN apk update
RUN apk upgrade
RUN apk --update add ca-certificates libressl
RUN update-ca-certificates
RUN apk --update add bash curl libstdc++ tzdata postgresql-client postgresql-dev
RUN apk --update add --virtual build_deps sudo build-base libc-dev libressl-dev zlib-dev
RUN echo 'gem: --no-document' > /etc/gemrc

RUN gem install bundler -v 2.3.27
RUN gem update --system 3.2.3
RUN bundle

CMD [ "bin/rails", "server" ]
