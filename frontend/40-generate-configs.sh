#!/bin/sh
set -e

# Generate /usr/share/nginx/html/config.js from environment variables.
# The browser loads this before the React bundle, populating window.env.
envsubst '${AUTHORITY} ${CLIENT_ID} ${CLIENT_SECRET}' \
  < /etc/nginx/config.js.template \
  > /usr/share/nginx/html/config.js
echo "Generated /usr/share/nginx/html/config.js"

# Generate /etc/nginx/conf.d/default.conf from template.
# Only the listed variables are substituted; nginx runtime vars ($host etc.) are left intact.
envsubst '${CURITY_SCHEME} ${CURITY_HOST} ${CURITY_PORT} ${API_HOST} ${API_PORT} ${GATEWAY_CREDENTIAL}' \
  < /etc/nginx/nginx.conf.template \
  > /etc/nginx/conf.d/default.conf
echo "Generated /etc/nginx/conf.d/default.conf"
