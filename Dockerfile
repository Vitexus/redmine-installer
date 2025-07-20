FROM ruby:3.1.4-bullseye
LABEL org.opencontainers.image.authors="support@easysoftware.com"
RUN apt-get update && apt-get -y install lsb-release wget curl vim
RUN wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb -O percona-release_latest_all.deb &&\
    dpkg -i percona-release_latest_all.deb &&\
    percona-release setup ps80 &&\
    apt-get update && apt-get install -y libperconaserverclient21-dev percona-server-client
WORKDIR /gem
VOLUME ["/gem/vendor/"]
COPY . ./
RUN bundle config set deployment 'true'
RUN bundle install
CMD ["bundle", "exec", "rspec"]
