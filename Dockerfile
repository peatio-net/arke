FROM ruby:3.3.8-slim AS builder

ARG UID=1000
ARG GID=1000

ENV APP_HOME=/home/app \
    TZ=UTC \
    DEBIAN_FRONTEND=noninteractive

# Install build dependencies including OpenSSL
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create group "app" and user "app"
RUN groupadd -r --gid ${GID} app \
    && useradd --system --create-home --home ${APP_HOME} --shell /sbin/nologin --no-log-init \
    --gid ${GID} --uid ${UID} app

WORKDIR $APP_HOME
USER app

# Copy dependency files first for better caching
COPY --chown=app:app Gemfile Gemfile.lock arke.gemspec VERSION $APP_HOME/

# Install bundler and gems with optimizations
#RUN gem install bundler --no-document \
#    && bundle config set --local deployment 'true' \
#    && bundle config set --local without 'test development' \
#    && bundle config set --local silence_root_warning 'true' \
#    && bundle config set --local jobs $(nproc) \
#    && bundle install \
#    && bundle clean --force \
#    && rm -rf /home/app/.bundle/cache

# Install bundler and gems with optimizations
RUN gem install bundler --no-document \
    && bundle config set --local deployment 'true' \
    && bundle config set --local without 'test development' \
    && bundle config set --local silence_root_warning 'true' \
    && bundle config set --local jobs $(nproc) \
    && bundle install \
    && bundle clean --force \
    && rm -rf /home/app/.bundle/cache


#    && bundle config set --local retry '3' \
#    && bundle config set --local timeout '15' \
#    && bundle config set --local force_ruby_platform 'true' \

# Copy the main application
COPY --chown=app:app . $APP_HOME

# Remove unnecessary files
RUN rm -rf \
    .git \
    .gitignore \
    .dockerignore \
    README* \
    CHANGELOG* \
    spec \
    test \
    tmp/* \
    log/* \
    && find . -name "*.md" -delete \
    && find . -name ".DS_Store" -delete

# Production stage - minimal runtime image
FROM ruby:3.3.8-slim AS production

ARG UID=1000
ARG GID=1000

ENV APP_HOME=/home/app \
    TZ=UTC \
    RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT=development:test \
    DEBIAN_FRONTEND=noninteractive \
    RUBY_GC_HEAP_INIT_SLOTS=10000 \
    RUBY_GC_HEAP_FREE_SLOTS=4000 \
    RUBY_GC_HEAP_GROWTH_FACTOR=1.1 \
    RUBY_GC_HEAP_GROWTH_MAX_SLOTS=10000 \
    RUBY_GC_MALLOC_LIMIT=16777216 \
    RUBY_GC_MALLOC_LIMIT_MAX=33554432 \
    RUBY_GC_OLDMALLOC_LIMIT=16777216 \
    RUBY_GC_OLDMALLOC_LIMIT_MAX=33554432 \
    RUBY_YJIT_ENABLE=1 \
    BOOTSNAP_CACHE_DIR=/tmp/bootsnap


# Install only runtime dependencies including OpenSSL
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    libssl3 \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove -y

# Create group "app" and user "app"
RUN groupadd -r --gid ${GID} app \
    && useradd --system --create-home --home ${APP_HOME} --shell /sbin/nologin --no-log-init \
    --gid ${GID} --uid ${UID} app

WORKDIR $APP_HOME
USER app

# Copy bundler configuration
COPY --from=builder --chown=app:app /usr/local/bundle /usr/local/bundle

# Copy the application from builder stage
COPY --from=builder --chown=app:app $APP_HOME $APP_HOME

# Create necessary directories with proper permissions
RUN mkdir -p tmp log config \
    && chmod 755 tmp log config

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "arke start" || exit 1

# Use exec form for better signal handling
ENTRYPOINT ["bundle", "exec"]
CMD ["./bin/arke", "start"]
