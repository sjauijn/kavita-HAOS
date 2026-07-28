ARG BUILD_FROM
FROM ${BUILD_FROM}

ENV LANG="en_US.UTF-8" \
    HOME="/config" \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

ARG KAVITA_RELEASE
ARG TARGETARCH

RUN \
    apk add --no-cache \
        icu-libs \
        icu-data-full \
        curl \
        jq \
        tar \
        openssl \
        ca-certificates \
        su-exec \
        shadow \
    && mkdir -p /app/kavita \
    && if [ -z "${KAVITA_RELEASE}" ]; then \
        KAVITA_RELEASE="$(curl -sX GET "https://api.github.com/repos/Kareadita/Kavita/releases/latest" | jq -r '.tag_name')"; \
    fi \
    && case "${TARGETARCH}" in \
        amd64) KAVITA_ARCH="linux-x64" ;; \
        arm64) KAVITA_ARCH="linux-arm64" ;; \
        *) KAVITA_ARCH="linux-x64" ;; \
    esac \
    && curl -o /tmp/kavita.tar.gz -fL \
        "https://github.com/Kareadita/Kavita/releases/download/${KAVITA_RELEASE}/kavita-${KAVITA_ARCH}.tar.gz" \
    && tar xf /tmp/kavita.tar.gz -C /app/kavita --strip-components=1 --no-same-owner \
    && chmod +x /app/kavita/Kavita \
    && mkdir -p /defaults \
    && cp /app/kavita/config/appsettings-init.json /defaults/appsettings-init.json \
    && rm -rf /app/kavita/config \
    && rm -rf /tmp/* /var/cache/apk/*

# Add rootfs (s6 services)
COPY rootfs/ /

RUN chmod a+x /etc/s6-overlay/s6-rc.d/init-kavita-config/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/svc-kavita/run

EXPOSE 5000

############
# 5 Labels #
############
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ENV BUILD_VERSION="${BUILD_VERSION}"
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="sjauijn" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="sjauijn" \
    org.opencontainers.image.authors="sjauijn" \
    org.opencontainers.image.url="https://github.com/sjauijn/kavita-HAOS" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

HEALTHCHECK \
    --interval=10s \
    --retries=10 \
    --start-period=60s \
    --timeout=10s \
    CMD curl -kfsS "http://127.0.0.1:5000/api/health" || exit 1
