ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG KAVITA_RELEASE

RUN \
  apk add --no-cache \
    icu-libs \
    icu-data-full \
    curl \
    jq \
    tar \
    ca-certificates \
    openssl \
  && \
  mkdir -p /app/kavita && \
  if [ -z "${KAVITA_RELEASE}" ]; then \
    KAVITA_RELEASE=$(curl -sX GET "https://api.github.com/repos/Kareadita/Kavita/releases/latest" | jq -r '.tag_name'); \
  fi && \
  curl -o /tmp/kavita.tar.gz -fL \
    "https://github.com/Kareadita/Kavita/releases/download/${KAVITA_RELEASE}/kavita-linux-musl-x64.tar.gz" && \
  tar xf /tmp/kavita.tar.gz -C /app/kavita --strip-components=1 --no-same-owner && \
  chmod +x /app/kavita/Kavita && \
  cp -r /app/kavita/config /defaults && \
  rm -rf /app/kavita/config && \
  rm -rf /tmp/*

COPY run.sh /
RUN chmod a+x /run.sh

LABEL \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.version=${BUILD_VERSION}

CMD [ "/run.sh" ]
