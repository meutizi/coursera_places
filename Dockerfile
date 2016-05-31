FROM ruby:2.3.1
RUN apt-get update -qq && apt-get install -y build-essential nodejs libpq-dev && mkdir -p /var/app
WORKDIR /var/app
COPY Gemfile /var/app/Gemfile
RUN bundle install