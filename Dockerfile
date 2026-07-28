ARG BUILD_FROM
FROM ${BUILD_FROM}

# Kavita is a self-contained .NET app published by the Kavita team as a
# linux-x64 tarball, so we don't need the dotnet SDK/runtime in the image.
ENV LANG="en_US.UTF-8" \
    KAVITA_INSTALL_DIR="/app/kavita"

RUN \
    apk add --no-cache \
        icu-libs \
        icu-data-full \
        curl \
        jq \
        tar \
        ca-certificates \
        su-exec \
        shadow \
    && mkdir -p "${KAVITA_INSTALL_DIR}" \
    && KAVITA_RELEASE="$(curl -sX GET "https://api.github.com/repos/Kareadita/Kavita/releases/latest" \
        | jq -r '.tag_name')" \
    && curl -o /tmp/kavita.tar.gz -fL \
        "https://github.com/Kareadita/Kavita/releases/download/${KAVITA_RELEASE}/kavita-linux-x64.tar.gz" \
    && tar xf /tmp/kavita.tar.gz -C "${KAVITA_INSTALL_DIR}" --strip-components=1 --no-same-owner \
    && chmod +x "${KAVITA_INSTALL_DIR}/Kavita" \
    && cp "${KAVITA_INSTALL_DIR}/config/appsettings-init.json" /appsettings-init.json \
    && rm -rf "${KAVITA_INSTALL_DIR}/config" \
    && rm -rf /tmp/* /var/cache/apk/*

COPY run.sh /
RUN chmod a+x /run.sh

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

CMD [ "/run.sh" ]
