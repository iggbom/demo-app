FROM curity.azurecr.io/curity/idsvr:latest

# Copy config template (redirect URIs and DB connection are substituted at startup)
COPY config.xml.template /opt/idsvr/etc/init/config.xml.template

# Wrapper entrypoint: writes license from env var, envsubsts config, then execs original
COPY docker-entrypoint.sh /opt/idsvr/bin/docker-entrypoint-custom.sh
USER root
RUN chmod +x /opt/idsvr/bin/docker-entrypoint-custom.sh

ENTRYPOINT ["/opt/idsvr/bin/docker-entrypoint-custom.sh"]
