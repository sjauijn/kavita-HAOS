#!/usr/bin/with-contenv bashio

DATA_LOCATION="$(bashio::config 'data_location')"
PORT=5000
TZ_VALUE="$(bashio::config 'tz')"
SSL="$(bashio::config 'ssl')"
CERTFILE="$(bashio::config 'certfile')"
KEYFILE="$(bashio::config 'keyfile')"

export TZ="${TZ_VALUE}"

mkdir -p "${DATA_LOCATION}"
mkdir -p "${DATA_LOCATION}/config"

if [ ! -f "${DATA_LOCATION}/config/appsettings.json" ]; then
  bashio::log.info "No existing appsettings.json found, seeding defaults"
  cp -n /defaults/appsettings.json "${DATA_LOCATION}/config/appsettings.json" 2>/dev/null \
    || cp -n /defaults/appsettings-init.json "${DATA_LOCATION}/config/appsettings.json"
fi

CURRENT_PORT="$(jq -r '.Port // empty' "${DATA_LOCATION}/config/appsettings.json")"
if [ "${CURRENT_PORT}" != "${PORT}" ]; then
  bashio::log.info "Updating configured port to ${PORT}"
  jq --argjson port "${PORT}" '.Port = $port' "${DATA_LOCATION}/config/appsettings.json" > /tmp/appsettings.json \
    && mv /tmp/appsettings.json "${DATA_LOCATION}/config/appsettings.json"
fi

rm -rf /app/kavita/config
ln -sfn "${DATA_LOCATION}/config" /app/kavita/config

SCHEME="http"

if bashio::var.true "${SSL}"; then
  CERT_PATH="/ssl/${CERTFILE}"
  KEY_PATH="/ssl/${KEYFILE}"

  if [ ! -f "${CERT_PATH}" ] || [ ! -f "${KEY_PATH}" ]; then
    bashio::log.warning "SSL enabled but ${CERT_PATH} or ${KEY_PATH} not found, falling back to HTTP"
  else
    bashio::log.info "Enabling HTTPS with ${CERT_PATH}"
    mkdir -p /tmp/kavita-ssl
    PFX_PATH="/tmp/kavita-ssl/kavita.pfx"
    PFX_PASSWORD="$(head -c16 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    openssl pkcs12 -export \
      -out "${PFX_PATH}" \
      -inkey "${KEY_PATH}" \
      -in "${CERT_PATH}" \
      -passout "pass:${PFX_PASSWORD}"

    export ASPNETCORE_Kestrel__Certificates__Default__Path="${PFX_PATH}"
    export ASPNETCORE_Kestrel__Certificates__Default__Password="${PFX_PASSWORD}"
    export ASPNETCORE_Kestrel__EndpointDefaults__Protocols="Http1AndHttp2"
    SCHEME="https"
  fi
fi

export ASPNETCORE_URLS="${SCHEME}://0.0.0.0:${PORT}"

bashio::log.info "Starting Kavita, data at ${DATA_LOCATION}, port ${PORT}, TZ ${TZ_VALUE}, scheme ${SCHEME}"

cd /app/kavita || exit 1

exec ./Kavita
