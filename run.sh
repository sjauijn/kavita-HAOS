#!/usr/bin/with-contenv bashio

DATA_LOCATION="$(bashio::config 'data_location')"
PORT=5000
INTERNAL_PORT=5001
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

rm -rf /app/kavita/config
ln -sfn "${DATA_LOCATION}/config" /app/kavita/config

SSL_ACTIVE=false

if bashio::var.true "${SSL}"; then
  CERT_PATH="/ssl/${CERTFILE}"
  KEY_PATH="/ssl/${KEYFILE}"

  if [ ! -f "${CERT_PATH}" ]; then
    bashio::log.warning "SSL enabled but certificate file ${CERT_PATH} was not found, falling back to HTTP"
    KAVITA_PORT="${PORT}"
  elif [ ! -f "${KEY_PATH}" ]; then
    bashio::log.warning "SSL enabled but key file ${KEY_PATH} was not found, falling back to HTTP"
    KAVITA_PORT="${PORT}"
  else
    bashio::log.info "Enabling HTTPS termination with nginx using ${CERT_PATH}"
    KAVITA_PORT="${INTERNAL_PORT}"
    SSL_ACTIVE=true

    mkdir -p /tmp/nginx/logs
    mkdir -p /tmp/nginx/tmp/client_body
    mkdir -p /tmp/nginx/tmp/proxy
    mkdir -p /tmp/nginx/tmp/fastcgi
    mkdir -p /tmp/nginx/tmp/uwsgi
    mkdir -p /tmp/nginx/tmp/scgi
    mkdir -p /tmp/nginx/conf

    cat > /tmp/nginx/conf/nginx.conf << NGINXCONF
pid /tmp/nginx/nginx.pid;
error_log /tmp/nginx/logs/error.log warn;
worker_processes 1;
daemon off;
user root;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    client_body_temp_path /tmp/nginx/tmp/client_body;
    proxy_temp_path /tmp/nginx/tmp/proxy;
    fastcgi_temp_path /tmp/nginx/tmp/fastcgi;
    uwsgi_temp_path /tmp/nginx/tmp/uwsgi;
    scgi_temp_path /tmp/nginx/tmp/scgi;
    access_log /tmp/nginx/logs/access.log;

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
}
NGINXCONF

    if ! nginx -c /tmp/nginx/conf/nginx.conf -e /tmp/nginx/logs/error.log -t; then
      bashio::log.error "nginx configuration test failed, falling back to HTTP"
      SSL_ACTIVE=false
      KAVITA_PORT="${PORT}"
    else
      nginx -c /tmp/nginx/conf/nginx.conf -e /tmp/nginx/logs/error.log &
      NGINX_PID=$!

      sleep 1

      if ! kill -0 "${NGINX_PID}" 2>/dev/null; then
        bashio::log.error "nginx failed to start, see below, falling back to HTTP"
        cat /tmp/nginx/logs/error.log 2>/dev/null
        SSL_ACTIVE=false
        KAVITA_PORT="${PORT}"
      fi

      cleanup() {
        if [ -n "${NGINX_PID}" ] && kill -0 "${NGINX_PID}" 2>/dev/null; then
          kill "${NGINX_PID}" 2>/dev/null
        fi
      }
      trap cleanup EXIT TERM INT
    fi
  fi
else
  KAVITA_PORT="${PORT}"
fi

CURRENT_PORT="$(jq -r '.Port // empty' "${DATA_LOCATION}/config/appsettings.json")"
if [ "${CURRENT_PORT}" != "${KAVITA_PORT}" ]; then
  bashio::log.info "Updating configured port to ${KAVITA_PORT}"
  jq --argjson port "${KAVITA_PORT}" '.Port = $port' "${DATA_LOCATION}/config/appsettings.json" > /tmp/appsettings.json \
    && mv /tmp/appsettings.json "${DATA_LOCATION}/config/appsettings.json"
fi

bashio::log.info "Starting Kavita, data at ${DATA_LOCATION}, port ${KAVITA_PORT}, TZ ${TZ_VALUE}"

cd /app/kavita || exit 1

if [ "${SSL_ACTIVE}" = "true" ]; then
  ./Kavita
  cleanup
  exit 0
fi

exec ./Kavita
