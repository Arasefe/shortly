#!/bin/sh
# Launch nginx (the web server) and node (the app) together in one container.
# nginx stays in the foreground as PID 1; node runs behind it on loopback.
set -e

# self-signed TLS cert on first start - the key lives only in the running
# container, never in an image layer (lab only; production uses a real CA)
if [ ! -f /etc/nginx/certs/shortly.crt ]; then
  mkdir -p /etc/nginx/certs
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout /etc/nginx/certs/shortly.key \
    -out    /etc/nginx/certs/shortly.crt \
    -subj "/CN=shortly.lab"
fi

# the app, on the container's loopback (not published; only nginx is)
node dist/server.js &
APP=$!

# a clean shutdown stops both
trap 'kill "$APP" 2>/dev/null; nginx -s quit 2>/dev/null' TERM INT

# the web server, in the foreground - keeps the container alive
nginx -g 'daemon off;'
