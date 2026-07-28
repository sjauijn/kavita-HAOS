ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base:7.6.1
FROM ${BUILD_FROM}

# set version label
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ARG KAVITA_RELEASE

ENV LANG="C.UTF-8" \
    HOME="/config"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install runtime dependencies required by Kavita (self-contained .NET binary)
RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        libicu-dev \
        ca-certificates \
        tzdata \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Determine the correct Kavita release asset for this architecture and
# unpack it into /app/kavita
RUN \
    set -eux; \
    case "${BUILD_ARCH}" in \
        amd64) KAVITA_ARCH="linux-x64" ;; \
        aarch64) KAVITA_ARCH="linux-arm64" ;; \
        *) echo "Unsupported arch: ${BUILD_ARCH}" >&2; exit 1 ;; \
    esac; \
    if [ -z "${KAVITA_RELEASE:-}" ]; then \
        KAVITA_RELEASE=$(curl -sX GET "https://api.github.com/repos/kareadita/kavita/releases/latest" | jq -r '.tag_name'); \
    fi; \
    mkdir -p /app/kavita; \
    curl -o /tmp/kavita.tar.gz -fL \
        "https://github.com/Kareadita/Kavita/releases/download/${KAVITA_RELEASE}/kavita-${KAVITA_ARCH}.tar.gz"; \
    tar xf /tmp/kavita.tar.gz -C /app/kavita --strip-components=1 --no-same-owner; \
    chmod +x /app/kavita/Kavita; \
    mkdir -p /defaults; \
    cp /app/kavita/config/appsettings-init.json /defaults/appsettings-init.json; \
    rm -rf /app/kavita/config; \
    rm -rf /tmp/*

# Copy S6 services and helper scripts
COPY rootfs /

RUN chmod a+x /etc/services.d/kavita/run \
    && chmod a+x /etc/cont-init.d/*.sh

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="you" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
