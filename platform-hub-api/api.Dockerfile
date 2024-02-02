FROM ruby:2.3.8

WORKDIR /platform-hub-api
COPY . .

RUN gem install bundler -v 2.3.27
RUN bundle
RUN bin/rails db:setup

CMD [ "bin/rails", "server" ]