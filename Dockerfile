# syntax=docker/dockerfile:1
# vfeeg-keycloak EDA backend EEGFaktura
# Copyright (C) 2023  Matthias Poettinger
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

FROM quay.io/keycloak/keycloak:latest as builder
LABEL org.vfeeg.vendor="Verein zur Förderung von Erneuerbaren Energiegemeinschaften"
LABEL org.vfeeg.image.authors="eegfaktura@vfeeg.org"
LABEL org.opencontainers.image.vendor="Verein zur Förderung von Erneuerbaren Energiegemeinschaften"
LABEL org.opencontainers.image.authors="eegfaktura@vfeeg.org"
LABEL org.opencontainers.image.title="eegfaktura-keycloak"
LABEL org.opencontainers.image.version="0.1.0"
LABEL org.opencontainers.image.description="EEG Faktura keycloak auth"
LABEL org.opencontainers.image.licenses=AGPL-3.0
LABEL org.opencontainers.image.source=https://github.com/eegfaktura/eegfaktura-web
LABEL org.opencontainers.image.base.name=quay.io/keycloak/keycloak:latest
LABEL description="EEG Faktura keycloak auth"
LABEL version="0.1.0"

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database vendor
ENV KC_DB=postgres

WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres
ENV KC_DB_URL=jdbc:postgresql://eegfaktura-postgresql:5432/keycloak
ENV KEYCLOAK_ADMIN=admin
ENV KC_HOSTNAME_STRICT=false
ENV KC_HOSTNAME_STRICT_HTTPS=false
ENV KC_HTTP_ENABLED=true
ENV PROXY_ADDRESS_FORWARDING=true
ENV KC_HOSTNAME_STRICT_BACKCHANNEL=false
ENV KC_HOSTNAME_PATH="/auth"
ENV KC_PROXY=edge


ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start"]

