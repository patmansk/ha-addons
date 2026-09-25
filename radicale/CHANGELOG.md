# Changelog

## 3.8.9

- Fixed runtime error when using `conversion_bday_summary_template` with multiple VEVENTs
- Improved template handling to prevent INI format breaks with special characters

## 3.8.8

- Bumped version to 3.8.8 to trigger add-on update detection in HAOS

## 3.8.7

- Bumped version to 3.8.7 to trigger add-on update detection in HAOS (feature changes from 3.8.6 already included)

## 3.8.6

- Added `conversion_bday_*` options for birthday calendar conversion
- New options:
  - `bday_summary_template`: Template for birthday event summary (default: "Birthday: {name}")
  - `bday_description_template`: Template for birthday event description (default: "{name} is turning {age}")
  - `bday_alarm_trigger_template`: Alarm trigger template (default: "PT0S")
  - `bday_categories`: Categories for birthday events (default: "[]")
  - `bday_age_max`: Maximum age for birthday events (default: 0)

## 3.8.0.0

- Initial release
- Radicale 3.8.0
- htpasswd authentication support
- Persistent storage via shared folder
- Configurable via add-on options
## 3.8.10

- Added `icon: icon.png` and `logo: logo.png` to config.yaml for proper HAOS UI display
- Added `documentation: DOCS.md` to enable the Documentation tab in HAOS
- Fixed version inconsistency (was reverted to 3.8.7, now properly bumped)
- Fixed `run.sh` jq queries to correctly read `conversion_bday_*` options from user settings
- Added missing `conversion_bday_categories` option to schema
