# Kavita

Self-hosted digital library server for EPUB, PDF, CBZ/CBR comics and manga.

## Options

- `data_location`: path (inside the addon container) where your library lives. Defaults to `/share/kavita`. Point it at any subpath under `/share` or `/media`, e.g. `/media/MegaCloud/kavita`, as long as it's mapped into Home Assistant.
- `TZ`: timezone, e.g. `Europe/Paris`.
- `ssl`: enable HTTPS. When enabled, the addon reads `certfile`/`keyfile` from the Home Assistant `/ssl` folder, bundles them into a PKCS12 file, and configures Kavita's Kestrel server to serve HTTPS on port 5000.
- `certfile` / `keyfile`: filenames (not full paths) of your certificate and private key inside `/ssl`, e.g. `fullchain.pem` / `privkey.pem`.

## Web UI

Once started, open the addon's web UI (port 5000). Complete Kavita's setup wizard and point the library path to your configured `data_location`.
