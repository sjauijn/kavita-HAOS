#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Prepares the Kavita data directory, timezone and (optional) SSL certificates
# before the Kavita service starts.
# ==============================================================================

set -o errexit
set -o nounset
set -o pipefail

DATA_LOCATION="$(bashio::config 'data_location')"
TZ_VALUE="$(bashio::config 'tz')"
SSL_ENABLED="$(bashio::config 'ssl')"
CERTFILE="$(bashio::config 'certfile')"
KEYFILE="$(bashio::config 'keyfile')"
WEB_PORT="$(bashio::config 'port')"

# ------------------------------------------------------------------------
# Timezone
# ------------------------------------------------------------------------
if [[ -n "${TZ_VALUE}" ]] && [[ -f "/usr/share/zoneinfo/${TZ_VALUE}" ]]; then
    bashio::log.info "Setting timezone to ${TZ_VALUE}"
    ln -snf "/usr/share/zoneinfo/${TZ_VALUE}" /etc/localtime
    echo "${TZ_VALUE}" > /etc/timezone
else
    bashio::log.warning "Timezone '${TZ_VALUE}' is not valid, keeping default"
fi

# ------------------------------------------------------------------------
# Data directory
#
# Kavita expects its persistent config/data at /config. We honor the
# user-selected data_location (defaults to /share/kavita) and symlink it
# to /config so the Kavita binary works unmodified.
# ------------------------------------------------------------------------
bashio::log.info "Using data location: ${DATA_LOCATION}"

if [[ ! -d "${DATA_LOCATION}" ]]; then
    bashio::log.info "Creating data directory at ${DATA_LOCATION}"
    mkdir -p "${DATA_LOCATION}"
fi

# (Re)create the /config symlink to point at the configured data location
if [[ -L /config ]]; then
    rm -f /config
elif [[ -d /config ]]; then
    bashio::log.warning "Removing unexpected /config directory"
    rm -rf /config
fi
ln -snf "${DATA_LOCATION}" /config

# Seed default settings on first run
if [[ ! -f "/config/appsettings.json" ]]; then
    bashio::log.info "No appsettings.json found, seeding defaults"
    cp /defaults/appsettings-init.json /config/appsettings.json
fi

# ------------------------------------------------------------------------
# SSL
#
# Kavita (via Kestrel/.NET) ignores its own Port/SSL settings when it
# detects it's running in a Docker/container. Instead we drive HTTP/HTTPS
# binding and certificates entirely through standard ASP.NET Core
# environment variables, which are read by Kestrel directly and are
# honored regardless of Kavita's own container detection.
# ------------------------------------------------------------------------
mkdir -p /etc/kavita
: > /etc/kavita/env

if bashio::config.true 'ssl'; then
    CERT_PATH="/ssl/${CERTFILE}"
    KEY_PATH="/ssl/${KEYFILE}"

    if [[ ! -f "${CERT_PATH}" ]]; then
        bashio::log.fatal "SSL is enabled but certificate file was not found: ${CERT_PATH}"
        bashio::exit.nok
    fi
    if [[ ! -f "${KEY_PATH}" ]]; then
        bashio::log.fatal "SSL is enabled but key file was not found: ${KEY_PATH}"
        bashio::exit.nok
    fi

    bashio::log.info "SSL enabled, using certificate ${CERT_PATH}"
    {
        echo "ASPNETCORE_URLS=https://0.0.0.0:${WEB_PORT}"
        echo "ASPNETCORE_Kestrel__Endpoints__Https__Url=https://0.0.0.0:${WEB_PORT}"
        echo "ASPNETCORE_Kestrel__Endpoints__Https__Certificate__Path=${CERT_PATH}"
        echo "ASPNETCORE_Kestrel__Endpoints__Https__Certificate__KeyPath=${KEY_PATH}"
    } >> /etc/kavita/env
else
    bashio::log.info "SSL disabled, serving plain HTTP"
    echo "ASPNETCORE_URLS=http://0.0.0.0:${WEB_PORT}" >> /etc/kavita/env
fi

echo "TZ=${TZ_VALUE}" >> /etc/kavita/env

bashio::log.info "Kavita setup complete"
