FROM ruby:3.3.5-alpine AS builder

ARG UID=1000
ARG GID=1000

ENV APP_HOME=/home/app \
    TZ=UTC

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    linux-headers

# Create user
RUN addgroup -g ${GID} -S app \
    && adduser -u ${UID} -S app -G app -h ${APP_HOME}

WORKDIR $APP_HOME
USER app

# Copy and install dependencies
COPY --chown=app:app Gemfile Gemfile.lock arke.gemspec VERSION $APP_HOME/

RUN gem install bundler --no-document 

RUN  bundle config set --local deployment 'true'

RUN  bundle config set --local without 'test development'

#    && bundle config set --local jobs $(nproc) \
#    && bundle install \
#    && bundle clean --force

# Copy the main application.
COPY --chown=app:app . $APP_HOME

# Clean up
RUN rm -rf .git spec test tmp/* log/* \
    && find . -name "*.md" -delete

# Production stage
FROM ruby:3.3.5-alpine AS production

ARG UID=1000
ARG GID=1000

ENV APP_HOME=/home/app \
    TZ=UTC \
    RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT=development:test \
    RUBY_GC_HEAP_INIT_SLOTS=10000 \
    RUBY_GC_HEAP_FREE_SLOTS=4000 \
    RUBY_GC_HEAP_GROWTH_FACTOR=1.1 \
    RUBY_GC_MALLOC_LIMIT=16777216 \
    RUBY_GC_MALLOC_LIMIT_MAX=33554432 \
    BOOTSNAP_CACHE_DIR=/tmp/bootsnap

# Install only runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata

# Create user
RUN addgroup -g ${GID} -S app \
    && adduser -u ${UID} -S app -G app -h ${APP_HOME}

WORKDIR $APP_HOME
USER app

# Copy from builder
COPY --from=builder --chown=app:app /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=app:app $APP_HOME $APP_HOME

# Create directories
RUN mkdir -p tmp log config

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "arke start" || exit 1

ENTRYPOINT ["bundle", "exec"]
CMD ["./bin/arke", "start"]