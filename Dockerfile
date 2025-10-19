# syntax=docker/dockerfile:1.6
# Multi-stage optimized build for AWS App Runner
FROM ruby:3.3-slim AS base

# Environment setup
ENV BUNDLE_DEPLOYMENT=1 \
  RACK_ENV=production \
  RAILS_ENV=production \
  TZ=UTC \
  RAILS_LOG_TO_STDOUT=1 \
  RUBY_YJIT_ENABLE=1

# Install runtime dependencies + postgres client + jemalloc
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  libpq5 \
  libjemalloc2 \
  libyaml-0-2 \
  ca-certificates \
  tzdata \
  && rm -rf /var/lib/apt/lists/*

# jemalloc for better memory performance
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

WORKDIR /app

FROM base AS gems

# Install build dependencies for native extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  git \
  libpq-dev \
  pkg-config \
  libyaml-dev \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
  bundle install --jobs 4 --retry 3

FROM base AS app

# Copy installed gems from the gems stage
COPY --from=gems /usr/local/bundle /usr/local/bundle

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p tmp/pids tmp/sockets log storage && \
  chmod +x bin/docker-entrypoint

# App Runner expects the app to listen on port 8080 by default
# But we'll use PORT env var for flexibility
ENV PORT=3000

# Expose port
EXPOSE 3000

# Healthcheck for App Runner (adjusts to your health endpoint)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://127.0.0.1:${PORT}/health || exit 1

# Use custom entrypoint script
ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
