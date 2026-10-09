# Stage 1: Build the Flutter web application
FROM debian:bookworm-slim AS build

# Install dependencies required by Flutter
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Clone official Flutter stable SDK
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Configure git and Flutter
RUN git config --global --add safe.directory /usr/local/flutter && \
    flutter config --no-analytics --enable-web && \
    flutter precache --web

WORKDIR /app

# Cache dependency layer
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Build the web application
COPY . .
RUN flutter build web --release --base-href=/

# Stage 2: Serve the static files with Nginx
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8044

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8044/ || exit 1
