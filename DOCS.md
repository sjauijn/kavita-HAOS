# Kavita — Home Assistant Add-on

Self-hosted digital library server for EPUB, PDF, comics (CBZ/CBR/CB7) and manga, packaged as a Home Assistant add-on.

## Quick Start

1. Copy your book/comic files somewhere under `/share` or `/media` on your Home Assistant host (e.g. `/share/books`).
2. Install and start the add-on.
3. Open the Web UI (button on the add-on's Info tab, or `http://homeassistant.local:5000`).
4. Complete the Kavita setup wizard: create an admin account.
5. Go to **Server Settings → Libraries → Add Library**, and point it at the folder under `/share` or `/media` where your books live (visible inside the add-on container at the same path).

## Configuration Options

| Option | Default | Description |
|--------|---------|--------------|
| `puid` | `1000` | User ID Kavita will run as. Match this to the owner of your book files if you hit permission errors. |
| `pgid` | `1000` | Group ID Kavita will run as. |
| `tz` | `Etc/UTC` | Timezone, e.g. `Europe/Minsk`. |

## Persistent Data

Kavita's database (SQLite), covers cache, logs and settings are stored under the add-on's own persistent config storage, so they survive add-on restarts and updates. Your library files themselves live wherever you point Kavita (`/share/...` or `/media/...`), untouched by the add-on.

## Notes

- This add-on downloads the latest official Kavita release (`linux-x64`) from the [Kavita GitHub releases](https://github.com/Kareadita/Kavita/releases) at build time. To pin a specific version, edit the Dockerfile's release lookup.
- No external database is required — Kavita uses an embedded SQLite database.
- If you also run Jellyfin, this add-on runs independently and can point at a different (or overlapping, read-only) folder for your library.
