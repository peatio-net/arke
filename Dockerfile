FROM ruby:3.2.2-slim

ARG UID=1000
ARG GID=1000

ENV APP_HOME=/home/app \
    TZ=UTC

# Install system dependencies.
RUN apt-get update && apt-get upgrade -y

# Create group "app" and user "app".
RUN groupadd -r --gid ${GID} app \
    && useradd --system --create-home --home ${APP_HOME} --shell /sbin/nologin --no-log-init \
    --gid ${GID} --uid ${UID} app

WORKDIR $APP_HOME
USER app

COPY --chown=app:app Gemfile Gemfile.lock arke.gemspec VERSION $APP_HOME/

# Install dependencies
RUN gem install bundler
RUN bundle install --jobs=$(nproc) --without test development

# Optimized bundler configuration
RUN bundle config set --local deployment 'true'
RUN bundle config set --local without 'test development'
RUN bundle clean --force

# Copy the main application.
COPY --chown=app:app . $APP_HOME
