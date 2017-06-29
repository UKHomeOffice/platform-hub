FROM quay.io/ukhomeofficedigital/centos-base

ENV RUBY_VERSION 2.3.3
ENV RAILS_ENV production
ENV RACK_ENV production

# Update kernel-headers & existing packages, install dependencies
RUN yum install -y wget \
    && wget http://cbs.centos.org/kojifiles/packages/kernel/4.9.31/27.el7/x86_64/kernel-headers-4.9.31-27.el7.x86_64.rpm \
    && rpm -ivh kernel-headers-4.9.31-27.el7.x86_64.rpm \
    && rm kernel-headers-4.9.31-27.el7.x86_64.rpm \
    && yum remove -y wget \
    && yum update -y \
    && yum install -y \
       which gcc-c++ patch readline readline-devel zlib zlib-devel \
       libyaml-devel libffi-devel openssl-devel make bzip2 autoconf \
       automake libtool bison iconv-devel \
       postgresql-devel postgresql-libs postgresql-contrib \
    && curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
    && curl -L get.rvm.io | bash -s stable \
    && yum clean all

# Install Ruby v2.3.3 & Bundler
RUN /bin/bash -l -c "rvm requirements \
    && rvm install 2.3.3 \
    && rvm use 2.3.3 --default \
    && gem install bundler --no-ri --no-rdoc"

# Create app user, copy files, install bundle dependencies
WORKDIR /app
RUN groupadd -r app \
    && useradd -r -g app app
COPY . .
RUN /bin/bash -l -c "bundle install --jobs 20 --retry 5 --deployment --without development test --no-cache"

# Set permissions and start the server
RUN chown -R app:app /app
USER app
CMD /bin/bash -l -c "bundle exec rails s"
