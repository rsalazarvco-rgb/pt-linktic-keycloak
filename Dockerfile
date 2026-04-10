FROM quay.io/keycloak/keycloak:26.6.0
USER root
COPY ./backup/keycloak/cache-ispn.xml /opt/keycloak/conf/cache-ispn.xml
RUN chown keycloak:keycloak /opt/keycloak/conf/cache-ispn.xml
USER keycloak
RUN /opt/keycloak/bin/kc.sh build --features=http-optimized-serializers
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
