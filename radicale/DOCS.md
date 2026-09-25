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
| `bday_summary_template` | Template for the event summary. Available placeholders: `{fn}`, `{n:f}`, `{n:g}`, `{n:a}`, `{nickname}`, `{age}`, `{year}`, `{month}`, `{day}` | `[{n:f} {n:g}\|{fn}\|{nickname}] ({year}) (BDAY)` |
| `bday_description_template` | Template for the event description. Available placeholders: `{fn}`, `{n:f}`, `{n:g}`, `{n:a}`, `{nickname}`, `{age}`, `{year}`, `{month}`, `{day}` | `BDAY={year}-{month}-{day}` |
| `bday_alarm_trigger_template` | Alarm trigger(s) in ISO 8601 duration format, separated by `$` for multiple alarms. Each entry uses `<trigger>;<description>` format. Empty = no alarm | *(empty string)* |
| `bday_categories` | Category name(s) to assign to converted events (plain string, not JSON) | `Birthday` |
| `bday_age_max` | Maximum age to generate separate events for. **IMPORTANT:** Setting this to `0` is recommended for stability. If > 0, it generates one event per age, which may cause "Multiple main components" errors in Radicale <= 3.8.x. | `0` |

### Available Placeholders

The templates support the following placeholders (verified against `radicale.item.VCF_TO_ICS_SUPPORTED_PLACEHOLDERS`):

| Placeholder | Meaning |
|-------------|---------|
| `{fn}` | Full name (as in the contact) |
| `{n:f}` | First / given name |
| `{n:g}` | Last / family name |
| `{n:a}` | Additional name |
| `{nickname}` | Nickname (if set in the contact) |
| `{age}` | Age in years |
| `{year}` | Year of birth |
| `{month}` | Month of birth (01–12) |
| `{day}` | Day of birth (01–31) |

> **Note:** There is **no** `{name}` placeholder. Use `{fn}` for the full name.

### Example (Stable Configuration)

> ⚠️ **Wichtig:** `bday_age_max: 0` ist die empfohlene und stabile Einstellung.
> Werte > 0 führen zu einem bekannten Fehler ("Multiple main components") in Radicale,
> da mehrere VEVENTs ohne `RECURRENCE-ID` erzeugt werden.

```yaml
bday_summary_template: "[{n:f} {n:g}|{fn}|{nickname}] ({year}) (BDAY)"
bday_description_template: "BDAY={year}-{month}-{day}"
bday_alarm_trigger_template: "PT24H;Reminder"
bday_categories: "Birthday"
bday_age_max: 0
```

## Known Issues

### "Multiple main components" Error with `bday_age_max > 0`

If you set `bday_age_max` to a value greater than 0, Radicale generates one separate `VEVENT` for each age. Because these events do not contain a `RECURRENCE-ID`, Radicale's internal filter (`radicale/item/filter.py`) interprets them as multiple "main" components within a single calendar, which causes a `ValueError` and crashes the request.

**Workaround:**
Keep `bday_age_max` set to `0`. This generates a single recurring event (`RRULE=FREQ=YEARLY`) which is fully supported and stable.

**Upstream Issue:**
This is a known limitation/bug in Radicale's birthday conversion logic. See [Kozea/Radicale#2237](https://github.com/Kozea/Radicale/issues/2237).