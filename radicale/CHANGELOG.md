# Changelog

## 3.9.1

- Added `icon`, `logo`, and `documentation` fields to `config.yaml` for proper HAOS UI display
- Fixed `run.sh` jq queries to correctly read `conversion_bday_*` options from user settings
- Added missing `conversion_bday_categories` option to schema
- Updated Radicale version reference to 3.9.1

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
  - `bday_summary_template`: Template for birthday event summary
  - `bday_description_template`: Template for birthday event description
  - `bday_alarm_trigger_template`: Alarm trigger template
  - `bday_categories`: Categories for birthday events
  - `bday_age_max`: Maximum age for birthday events

## 3.8.0.0

- Initial release
- Radicale 3.8.0
- htpasswd authentication support
- Persistent storage via shared folder
- Configurable via add-on options
