#!/bin/sh
set -e

# Inject window.env config inline into the built index.html.
# Vite strips external <script src> tags during build, so we inject directly.
sed -i "s|</head>|<script>window.env={AUTHORITY:\"${AUTHORITY}\",CLIENT_ID:\"${CLIENT_ID}\",CLIENT_SECRET:\"${CLIENT_SECRET}\"};</script></head>|" \
  /usr/share/nginx/html/index.html
echo "Injected window.env into index.html"

# Derive the DNS resolver from /etc/resolv.conf so nginx can resolve
# .railway.internal hostnames at request time (127.0.0.11 is Docker-only).
# IPv6 addresses must be wrapped in brackets for the nginx resolver directive.
_RAW_RESOLVER=$(awk '/^nameserver/{print $2; exit}' /etc/resolv.conf)
case "$_RAW_RESOLVER" in
  *:*) NGINX_RESOLVER="[${_RAW_RESOLVER}]" ;;
  *)   NGINX_RESOLVER="${_RAW_RESOLVER}" ;;
esac
export NGINX_RESOLVER
echo "Using DNS resolver: ${NGINX_RESOLVER}"

# Generate /etc/nginx/conf.d/default.conf from template.
# Only the listed variables are substituted; nginx runtime vars ($host etc.) are left intact.
envsubst '${NGINX_RESOLVER} ${CURITY_SCHEME} ${CURITY_HOST} ${CURITY_PORT} ${CURITY_PUBLIC_HOST} ${API_SCHEME} ${API_HOST} ${API_PORT} ${GATEWAY_CREDENTIAL}' \
  < /etc/nginx/nginx.conf.template \
  > /etc/nginx/conf.d/default.conf
echo "Generated /etc/nginx/conf.d/default.conf"

# Connectivity test — runs inside Railway's network, result visible in deploy logs.
echo "Testing Curity connectivity: ${CURITY_SCHEME}://${CURITY_HOST}:${CURITY_PORT}"
wget -qO- --timeout=5 \
  "${CURITY_SCHEME}://${CURITY_HOST}:${CURITY_PORT}/oauth/v2/oauth-anonymous/.well-known/openid-configuration" \
  2>&1 | head -3 \
  && echo "Curity reachable OK" \
  || echo "Curity connectivity FAILED"

exec "$@"
