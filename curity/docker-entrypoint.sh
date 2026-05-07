#!/bin/sh
set -e

# Write license.json from the base64-encoded CURITY_LICENSE env var.
# On Railway there are no volume mounts, so the license must come in via env.
if [ -n "$CURITY_LICENSE" ]; then
  mkdir -p /opt/idsvr/etc/init/license
  printf '%s' "$CURITY_LICENSE" | base64 -d > /opt/idsvr/etc/init/license/license.json
  echo "License written from CURITY_LICENSE env var."
fi

# Substitute env vars into the config template and write the final config.
# Only the listed variables are expanded; Curity's own $-expressions are untouched.
envsubst '${CURITY_BASE_URL} ${FRONTEND_URL} ${CURITY_DB_URL} ${CURITY_DB_USER} ${CURITY_DB_PASS}' \
  < /opt/idsvr/etc/init/config.xml.template \
  > /opt/idsvr/etc/init/config.xml
echo "config.xml generated from template."

# Start Curity (CMD from base image is just the bare 'idsvr' binary on PATH).
exec idsvr "$@"
