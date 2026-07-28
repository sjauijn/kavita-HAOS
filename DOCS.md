# Kavita — Home Assistant add-on

[Kavita](https://www.kavitareader.com/) is a fast, feature rich, cross platform
reading server for Comics, Manga, Books and more.

## Installation

1. Add this repository to your Home Assistant add-on store.
2. Install the "Kavita" add-on.
3. Configure the options below.
4. Start the add-on.
5. Open the web UI (see "Open Web UI" button, or `http://<home-assistant-ip>:5000`).

## Configuration

```yaml
data_location: /share/kavita
port: 5000
ssl: false
certfile: fullchain.pem
keyfile: privkey.pem
tz: Europe/Paris
```

### Option: `data_location`

Path where Kavita stores its library database, configuration, cache and cover
images. Defaults to `/share/kavita`.

Because this add-on maps both the `share` (`/share`) and `media` (`/media`)
Home Assistant folders, you can point this at either, for example:

```yaml
data_location: /media/MegaCloud/kavita
```

The add-on creates the folder automatically if it doesn't already exist, and
symlinks it internally so Kavita always sees it at its expected `/config`
path.

> Note: this option only controls where Kavita's *own* database/config/cache
> lives. Your actual book/comic library folders are configured from inside
> the Kavita web UI itself (Admin → Libraries) and should point to a path
> under `/share/...` or `/media/...` as well, since those are the only
> folders mapped into the container.

### Option: `port`

The port the Kavita web server listens on inside the add-on container
(default `5000`).

If you change this value, you should also update the container-port mapping
on the add-on's **Network** tab to match, so Home Assistant forwards
requests to the correct internal port. The host-side port (the one you
actually browse to) can always be changed freely from the Network tab
without touching this option.

### Option: `ssl`

Set to `true` to serve the Kavita web interface over HTTPS, using a
certificate from Home Assistant's `/ssl` folder (the same folder used by
Home Assistant Core and other add-ons).

### Option: `certfile` / `keyfile`

Filenames (not full paths) of the certificate and private key inside `/ssl`.
Defaults match Home Assistant's own Let's Encrypt add-on output:

```yaml
certfile: fullchain.pem
keyfile: privkey.pem
```

### Option: `tz`

Timezone used by Kavita for scheduling and displayed timestamps, e.g.
`Europe/Paris`, `America/New_York`. Must be a valid
[IANA timezone name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

## First run

On first start, Kavita seeds a fresh configuration in `data_location`. Open
the web UI and follow Kavita's own setup wizard to create the initial admin
account and add libraries.

## Notes on SSL

Kavita's own in-app HTTP/HTTPS settings are ignored while running inside a
container (this is a known behavior of Kavita, not a limitation of this
add-on). Instead, this add-on configures HTTPS directly at the web-server
(Kestrel) level via environment variables, so the `ssl`/`certfile`/`keyfile`
options above are the correct — and only — way to enable HTTPS for this
add-on.

## Support

This is a community-built add-on port of Kavita, based on the official
[docker-kavita](https://github.com/linuxserver/docker-kavita) image
maintained by LinuxServer.io. For issues with Kavita itself, see the
[Kavita project](https://github.com/Kareadita/Kavita).
