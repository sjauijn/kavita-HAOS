#!/usr/bin/with-contenv bashio

DATA_LOCATION="$(bashio::config 'data_location')"
PORT=5000
INTERNAL_PORT=5001
TZ_VALUE="$(bashio::config 'tz')"
SSL="$(bashio::config 'ssl')"
CERTFILE="$(bashio::config 'certfile')"
KEYFILE="$(bashio::config 'keyfile')"
LOG_LEVEL="$(bashio::config 'log_level')"

export TZ="${TZ_VALUE}"

mkdir -p "${DATA_LOCATION}"
mkdir -p "${DATA_LOCATION}/config"

if [ ! -f "${DATA_LOCATION}/config/appsettings.json" ]; then
  bashio::log.info "No existing appsettings.json found, seeding defaults"
  cp -n /defaults/appsettings.json "${DATA_LOCATION}/config/appsettings.json" 2>/dev/null \
    || cp -n /defaults/appsettings-init.json "${DATA_LOCATION}/config/appsettings.json"
fi

CURRENT_PORT="$(jq -r '.Port // empty' "${DATA_LOCATION}/config/appsettings.json")"
if [ "${CURRENT_PORT}" != "${INTERNAL_PORT}" ]; then
  bashio::log.info "Updating configured port to ${INTERNAL_PORT}"
  jq --argjson port "${INTERNAL_PORT}" '.Port = $port' "${DATA_LOCATION}/config/appsettings.json" > /tmp/appsettings.json \
    && mv /tmp/appsettings.json "${DATA_LOCATION}/config/appsettings.json"
fi

jq --arg level "${LOG_LEVEL}" \
  '(.Serilog //= {}) | (.Serilog.MinimumLevel //= {}) | .Serilog.MinimumLevel.Default = $level' \
  "${DATA_LOCATION}/config/appsettings.json" > /tmp/appsettings.json \
  && mv /tmp/appsettings.json "${DATA_LOCATION}/config/appsettings.json"

rm -rf /app/kavita/config
ln -sfn "${DATA_LOCATION}/config" /app/kavita/config

if bashio::var.true "${SSL}"; then
  CERT_PATH="/ssl/${CERTFILE}"
  KEY_PATH="/ssl/${KEYFILE}"

  if [ ! -f "${CERT_PATH}" ] || [ ! -f "${KEY_PATH}" ]; then
    bashio::log.warning "SSL enabled but ${CERT_PATH} or ${KEY_PATH} not found, falling back to HTTP"
    export ASPNETCORE_URLS="http://0.0.0.0:${PORT}"
  else
    bashio::log.info "Enabling HTTPS termination with nginx using ${CERT_PATH}"
    export ASPNETCORE_URLS="http://127.0.0.1:${INTERNAL_PORT}"

    mkdir -p /run/nginx
    mkdir -p /etc/nginx/http.d
    rm -f /etc/nginx/http.d/default.conf

    cat > /etc/nginx/http.d/kavita.conf << NGINXCONF
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen ${PORT} ssl;
    listen [::]:${PORT} ssl;

    ssl_certificate ${CERT_PATH};
    ssl_certificate_key ${KEY_PATH};
    ssl_protocols TLSv1.2 TLSv1.3;

    client_max_body_size 0;
    proxy_read_timeout 3600s;
    proxy_send_timeout 3600s;

    location / {
        proxy_pass http://127.0.0.1:${INTERNAL_PORT};
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
    }
}
NGINXCONF

    nginx -t
    nginx
    NGINX_PID_FILE="/run/nginx.pid"

    cleanup() {
      if [ -f "${NGINX_PID_FILE}" ]; then
        kill "$(cat "${NGINX_PID_FILE}")" 2>/dev/null
      fi
    }
    trap cleanup EXIT TERM INT

    bashio::log.info "Starting Kavita, data at ${DATA_LOCATION}, port ${PORT} (HTTPS via nginx), TZ ${TZ_VALUE}, log level ${LOG_LEVEL}"

    cd /app/kavita || exit 1
    ./Kavita
    cleanup
    exit 0
  fi
fi

export ASPNETCORE_URLS="http://0.0.0.0:${PORT}"

bashio::log.info "Starting Kavita, data at ${DATA_LOCATION}, port ${PORT}, TZ ${TZ_VALUE}, log level ${LOG_LEVEL}"

cd /app/kavita || exit 1

exec ./Kavita
