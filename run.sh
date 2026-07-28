#!/usr/bin/with-contenv bashio

KAVITA_DIR="/app/kavita"
CONFIG_DIR="/data/kavita-config"

PUID="$(bashio::config 'puid')"
PGID="$(bashio::config 'pgid')"
TZ="$(bashio::config 'tz')"

export TZ

bashio::log.info "Starting Kavita add-on (PUID=${PUID} PGID=${PGID} TZ=${TZ})"

# Ensure persistent config directory exists and is seeded on first run
mkdir -p "${CONFIG_DIR}"
if [[ ! -f "${CONFIG_DIR}/appsettings.json" ]]; then
    bashio::log.info "No existing appsettings.json found, seeding defaults"
    cp /appsettings-init.json "${CONFIG_DIR}/appsettings.json"
fi

# Kavita expects its config directory at ${KAVITA_DIR}/config
rm -rf "${KAVITA_DIR}/config"
ln -s "${CONFIG_DIR}" "${KAVITA_DIR}/config"

# Create/adjust the abc user Kavita will run as, matching PUID/PGID
if ! getent group abc > /dev/null 2>&1; then
    addgroup -g "${PGID}" abc
fi
if ! getent passwd abc > /dev/null 2>&1; then
    adduser -D -H -u "${PUID}" -G abc abc
fi

# Give the runtime user ownership of its writable paths
chown -R abc:abc "${CONFIG_DIR}" "${KAVITA_DIR}/wwwroot/index.html" 2>/dev/null || true

# Make sure Kavita listens on all interfaces on port 5000 (required for
# HA's ingress/webui and host networking to reach it), without clobbering
# any other user-adjusted settings in appsettings.json.
if command -v jq > /dev/null 2>&1; then
    TMP_SETTINGS="$(mktemp)"
    jq '.Port = 5000 | .IpAddresses = "0.0.0.0"' "${CONFIG_DIR}/appsettings.json" > "${TMP_SETTINGS}" \
        && mv "${TMP_SETTINGS}" "${CONFIG_DIR}/appsettings.json"
fi

bashio::log.info "Handing off to Kavita on port 5000"

cd "${KAVITA_DIR}" || exit 1
exec su-exec abc:abc "${KAVITA_DIR}/Kavita"
