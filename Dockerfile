# Build the Flutter web app using the official Flutter Docker image (cirrusci)
# This avoids version mismatch issues and is more reliable
FROM cirrusci/flutter:3.27.1 AS build

WORKDIR /app

# Enable web support
RUN flutter config --enable-web

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --base-href=/

# Serve the generated static site.
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8044

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8044/ || exit 1
