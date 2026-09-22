# HA Add-ons

[![HA Add-ons](https://img.shields.io/badge/Home%20Assistant-Add--ons-blue)](https://www.home-assistant.io/addons/store/)

Collection of Home Assistant OS add-ons.

## Available Add-ons

| Add-on | Version | Description |
|--------|---------|-------------|
| [Radicale](radicale/) | 3.8.0.0 | CalDAV & CardDAV server (calendars, to-do lists, contacts) with htpasswd authentication |
| [Radicale DecSync](radicale-decsync/) | 1.2.12 | Radicale with DecSync storage integration for serverless calendar and contact synchronization |

## Installation

1. **Add this repository to Home Assistant:**
   - Go to **Settings → Add-ons → Add-on Store** (bottom-right)
   - Click the three-dot menu (top-right) → **Repositories**
   - Paste the URL: `https://github.com/patmansk/ha-addons`
   - Click **Add**

2. **Install the desired add-on:**
   - In the Add-on Store, find "Radicale" or "Radicale DecSync"
   - Click **Install**
   - Configure options as needed
   - **Start** the add-on

## Add-on Details

### Radicale

A lightweight CalDAV (calendars, to-do lists) and CardDAV (contacts) server.

- Based on [tomsquest/docker-radicale](https://hub.docker.com/r/tomsquest/docker-radicale) image
- htpasswd authentication support
- Persistent storage via shared folder
- Configurable via add-on options (auth, storage, server binding)

📖 [Documentation](radicale/DOCS.md) | [Changelog](radicale/CHANGELOG.md)

### Radicale DecSync

Radicale with integrated DecSync storage for serverless calendar and contact synchronization.

- No local storage required – data synced via DecSync
- Automatic DecSync integration

📖 [Documentation](radicale-decsync/DOCS.md) | [Changelog](radicale-decsync/CHANGELOG.md)

## Repository Structure

```
ha-addons/
├── repository.yaml              # HA repository metadata
├── .github/workflows/
│   └── release.yml             # Automated release on version change
├── radicale/                   # Radicale add-on
│   ├── config.yaml
│   ├── Dockerfile
│   ├── README.md
│   ├── DOCS.md
│   ├── CHANGELOG.md
│   ├── icon.png
│   └── translations/
└── radicale-decsync/           # Radicale DecSync add-on
    ├── config.yaml
    ├── Dockerfile
    ├── README.md
    ├── DOCS.md
    ├── CHANGELOG.md
    ├── icon.png
    ├── logo.png
    ├── patch_compatibility.py
    ├── run.sh
    └── translations/
```

## Maintainer

- [patmansk](https://github.com/patmansk)

## License

MIT