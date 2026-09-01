<p align="center">
  <img src="https://raw.githubusercontent.com/sjauijn/kavita-HAOS/refs/heads/main/icon.png" alt="icon">
</p>

# Kavita — Home Assistant app

I maintain this app, along my other apps and custom integrations for the Home Assistant, solely for my own use. As long as I'm actively using them myself, I'll continue developing and updating them; otherwise, support for apps and(or) custom integrations I no longer need will be discontinued.

## About

Fast, feature rich, cross platform reading server for Comics, Manga, Books
and more — packaged as a Home Assistant app.

- Configurable data/library storage location (`/share/...` or `/media/...`)
- Configurable web UI port
- Optional built-in SSL using certificates from Home Assistant's `/ssl` folder
- Configurable timezone

## Installation

1. Click to add the stable repository:
   [![Add Stable Repository](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/sjauijn/hassio-apps)
2. Or manually add:

   ```text
   https://github.com/sjauijn/hassio-apps
   ```

## Quick Start

```yaml
data_location: /share/kavita
ssl: false
certfile: fullchain.pem
keyfile: privkey.pem
tz: Europe/Paris
```

### Option: `data_location`

Path where Kavita stores its library database, configuration, cache and cover
images. Defaults to `/share/kavita`.

The add-on creates the folder automatically if it doesn't already exist, and
symlinks it internally so Kavita always sees it at its expected `/config`
path.

> Note: this option only controls where Kavita's *own* database/config/cache
> lives. Your actual book/comic library folders are configured from inside
> the Kavita web UI itself (Admin → Libraries) and should point to a path
> under `/share/...` or `/media/...` as well, since those are the only
> folders mapped into the container.

### Option: `ssl`

Set to `true` to serve the Kavita web interface over HTTPS, using a
certificate from Home Assistant's `/ssl` folder (the same folder used by
Home Assistant Core and other add-ons).

### Option: `certfile` / `keyfile`

Filenames (not full paths) of the certificate and private key inside `/ssl`.
Defaults match Home Assistant's own Let's Encrypt app output:

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

## Big thanks to:
[@Kareadita](https://github.com/Kareadita/Kavita) for awesome work

[@linuxserver](https://github.com/linuxserver/docker-kavita) for docker container
