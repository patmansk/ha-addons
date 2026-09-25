# Radicale for Home Assistant

Radicale is a small but powerful CalDAV (calendars, to-do lists) and CardDAV (contacts) server.

This add-on provides a pre-configured Radicale 3.9.1 instance for Home Assistant OS.

## Features

- CalDAV and CardDAV support
- htpasswd authentication
- Persistent storage via shared folder
- Configurable via add-on options
- Birthday calendar conversion (Radicale 3.8.0+)
- Lightweight (Alpine-based, ~41MB image)

## Configuration

All configuration is done through the add-on options panel. The options map directly to
Radicale configuration sections and keys via the `RADICALE_CONFIG_<SECTION>_<KEY>` format.

### Authentication

| Option | Description | Example |
|--------|-------------|---------|
| `auth_type` | Auth method: `none` or `htpasswd` | `htpasswd` |

**To set up htpasswd authentication:**
1. Stop the add-on
2. Create an htpasswd file in your shared folder:
   ```bash
   htpasswd -Bbn username password > /path/to/shared/users
   ```
3. Set `auth_type` to `htpasswd`
4. Start the add-on

### Storage

| Option | Description |
|--------|-------------|
| `storage_folder` | Directory for calendar/contact data (default: `/data/collections`) |

The data is stored in the Home Assistant shared folder, so it survives updates and restarts.

### Logging

| Option | Description |
|--------|-------------|
| `log_level` | Log level: `debug`, `info`, `warning`, `error`, `critical` (default: `info`) |

### Sharing

| Option | Description |
|--------|-------------|
| `sharing` | Sharing mode: `none` or `default` (default: `none`) |

### Birthday Calendar Conversion

Radicale 3.8.0+ supports automatic conversion of contact birthdays into calendar events.

| Option | Description |
|--------|-------------|
| `bday_summary_template` | Template for event summary (default: `[{n:f} {n:g}\|{fn}\|{nickname}] ({year}) (BDAY)`) |
| `bday_description_template` | Template for event description (default: `BDAY={year}-{month}-{day}`) |
| `bday_alarm_trigger_template` | Alarm trigger template (default: empty) |
| `bday_categories` | Calendar categories (default: `Birthday`) |
| `bday_age_max` | Maximum age to include (default: 0 = no limit) |

## Web Interface

The web interface is available at `http://[HOST]:[PORT:5232]`.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Full Documentation

See [DOCS.md](DOCS.md) for detailed configuration and usage instructions.