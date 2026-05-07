#!/bin/sh
set -e

# Inject window.env config inline into the built index.html.
# Vite strips external <script src> tags during build, so we inject directly.
sed -i "s|</head>|<script>window.env={AUTHORITY:\"${AUTHORITY}\",CLIENT_ID:\"${CLIENT_ID}\",CLIENT_SECRET:\"${CLIENT_SECRET}\"};</script></head>|" \
  /usr/share/nginx/html/index.html
echo "Injected window.env into index.html"

# Generate /etc/nginx/conf.d/default.conf from template.
# Only the listed variables are substituted; nginx runtime vars ($host etc.) are left intact.
envsubst '${CURITY_SCHEME} ${CURITY_HOST} ${CURITY_PORT} ${API_HOST} ${API_PORT} ${GATEWAY_CREDENTIAL}' \
  < /etc/nginx/nginx.conf.template \
  > /etc/nginx/conf.d/default.conf
echo "Generated /etc/nginx/conf.d/default.conf"

exec "$@"
