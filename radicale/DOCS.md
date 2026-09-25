# Radicale Add-on for Home Assistant

## Overview

Radicale is a small but powerful CalDAV (calendars, to-do lists) and CardDAV (contacts) server.
This add-on runs Radicale 3.8.0 inside a Docker container managed by the Home Assistant Supervisor.

## Configuration

All configuration is done through the add-on options panel. The options map directly to
Radicale configuration sections and keys via the `RADICALE_CONFIG_<SECTION>_<KEY>` format.

### Authentication

| Option | Description | Example |
|--------|-------------|---------|
| `RADICALE_CONFIG_AUTH_TYPE` | Auth method: `none`, `htpasswd`, `remote_user`, etc. | `htpasswd` |
| `RADICALE_CONFIG_AUTH_HTPASSWD_FILENAME` | Path to htpasswd file (must be in shared folder) | `/data/users` |
| `RADICALE_CONFIG_AUTH_HTPASSWD_ENCRYPTION` | Hash type: `bcrypt` or `apr_md5_crypt` | `bcrypt` |

**To set up htpasswd authentication:**
1. Stop the add-on
2. Create an htpasswd file in your shared folder:
   ```bash
   htpasswd -Bbn username password > /path/to/shared/users
   ```
   (or use any tool that generates htpasswd-compatible files)
3. Set `RADICALE_CONFIG_AUTH_TYPE` to `htpasswd`
4. Set `RADICALE_CONFIG_AUTH_HTPASSWD_FILENAME` to the path above
5. Start the add-on

### Storage

| Option | Description |
|--------|-------------|
| `RADICALE_CONFIG_STORAGE_FILESYSTEM_FOLDER` | Directory for calendar/contact data (default: `/data/collections`) |

The data is stored in the Home Assistant shared folder, so it survives updates and restarts.

### Server

| Option | Description | Default |
|--------|-------------|---------|
| `RADICALE_CONFIG_SERVER_HOSTS` | Bind address and port | `0.0.0.0:5232` |

## Connecting Clients

Once the add-on is running, connect your calendar/contact client to:

```
http://<home-assistant-ip>:5232
```

Or via the Home Assistant add-on proxy (if enabled):

```
http://<home-assistant-ip>:8123/api/addons/radicale/proxy/
```

### Example: Thunderbird + Lightning

1. Install the [Lightning](https://www.thunderbird.net/) extension
2. New Calendar → On the Network → CalDAV
3. URL: `http://<ha-ip>:5232`
4. Username/Password: as configured in htpasswd

### Example: Nextcloud / Syncthing / etc.

Point your client to `http://<ha-ip>:5232` with the configured credentials.

## Birthday Calendar Conversion

Radicale 3.8.0+ supports automatic conversion of birthday events from personal calendars into a separate "birthdays" calendar. The following options control this behavior:

| Option | Description | Default |
|--------|-------------|---------|
| `bday_summary_template` | Template for the event summary. Available variables: `{name}`, `{age}` | `Birthday: {name}` |
| `bday_description_template` | Template for the event description. Available variables: `{name}`, `{age}` | `{name} is turning {age}` |
| `bday_alarm_trigger_template` | Alarm trigger (ISO 8601 duration). Use `PT0S` for immediate | `PT0S` |
| `bday_categories` | JSON array of category names to assign | `[]` |
| `bday_age_max` | Maximum age to include (0 = no limit) | `0` |

### Example

```yaml
bday_summary_template: "🎂 {name} ({age})"
bday_description_template: "{name} celebrates their {age}th birthday!"
bday_alarm_trigger_template: "P1DT9H"  # 1 day and 9 hours before
bday_categories: '["Birthdays", "Family"]'
bday_age_max: 150
```

## Notes

- The add-on requires the `share` map type for persistent storage.
- For production use, enable htpasswd authentication and consider reverse-proxying with TLS.
- The add-on uses `init: true` and `watchdog: true` for automatic restart on crash.