# Home Assistant Automation: Radicale Update-Monitor

## Übersicht

Dieses Setup überwacht automatisch:
1. **GitHub Issue #2237** (Kozea/Radicale) – Wird es geschlossen?
2. **Neue Radicale-Releases** – Gibt es eine Version > 3.8.1?

Bei Änderungen wird eine **Benachrichtigung** in Home Assistant ausgelöst.

---

## Einrichtung

### 1. Benachrichtigung einrichten (einmalig)

In `configuration.yaml` (oder über die UI unter *Einstellungen → Automatisierung*):

```yaml
notify:
  - name: radicale_monitor
    platform: homeassistant
```

### 2. Automatisierung erstellen

Kopiere diese YAML in deine `automations.yaml`:

```yaml
alias: "Radicale Update Check"
description: "Prüft täglich, ob Radicale Issue #2237 behoben ist oder eine neue Version verfügbar ist."
trigger:
  - trigger: time
    at: "08:00:00"
condition: []
action:
  - action: shell_command.radicale_check
  - wait_template: "not none"
    timeout: "00:10:00"
  - action: notify.radicale_monitor
    data:
      title: "Radicale Update"
      message: "{{ states('sensor.radicale_check_result') }}"
mode: single
max: 1
```

### 3. Shell-Command definieren

In `configuration.yaml`:

```yaml
shell_command:
  radicale_check: /config/radicale_check.sh
```

### 4. Sensor definieren

In `sensor.yaml`:

```yaml
- platform: command_line
  name: "radicale_check_result"
  command: "cat /tmp/radicale_check_result.txt 2>/dev/null || echo 'Keine Prüfung durchgeführt.'"
  unit_of_measurement: "info"
```

### 5. Skript platzieren

Das Skript liegt im Add-on-Repository:
- **Quelldatei:** `radicale/automation_check_radicale.sh`
- **Ziel auf HAOS:** `/config/radicale_check.sh`

**Installation:**
```bash
# Auf dem HAOS-Host (SSH)
curl -o /config/radicale_check.sh \
  https://raw.githubusercontent.com/patmansk/ha-addons/main/radicale/automation_check_radicale.sh
chmod +x /config/radicale_check.sh

# Option: Webhook für Push-Notifications setzen
export NOTIFY_WEBHOOK_URL="https://your-ha-instance.local/api/webhook/YOUR_WEBHOOK_ID"
```

**Wichtig:** Das Skript schreibt das Ergebnis in `/tmp/radicale_check_result.txt`, damit der Sensor es lesen kann:

```bash
# Am Ende des Skripts (automatisch, falls nicht vorhanden):
echo "Issue #2237: $ISSUE_STATE | Latest Radicale: $LATEST_TAG" > /tmp/radicale_check_result.txt
```

---

## Alternative: Pure Webhook-Benachrichtigung

Falls du keine Shell-Befehle in HA nutzen möchtest, kannst du den Webhook direkt im Skript setzen:

```bash
NOTIFY_WEBHOOK_URL="https://your-ha-instance.local/api/webhook/YOUR_WEBHOOK_ID"
./radicale_check.sh
```

Das Skript sendet dann automatisch eine JSON-Nachricht an den Webhook.

---

## Was passiert bei einer Benachrichtigung?

| Ereignis | Nachricht |
|----------|-----------|
| Issue #2237 wird geschlossen | 🎉 "Fix verfügbar! Neue Radicale-Version prüfen." |
| Neue Radicale-Version > 3.8.1 | 🚀 "Neue Radicale-Version v<X.Y.Z> verfügbar. Add-on aktualisieren." |
| Keine Änderungen | *(Keine Benachrichtigung, nur Log-Ausgabe)* |

---

## Manuelle Prüfung

```bash
# Sofortige Prüfung ausführen
./radicale/automation_check_radicale.sh

# Mit Webhook
NOTIFY_WEBHOOK_URL="https://your-ha.local/api/webhook/12345" \
  ./radicale/automation_check_radicale.sh
```

---

## Cron-Einrichtung (alternative zu HA-Automatisierung)

Wenn du keine HA-Automatisierung nutzen möchtest:

```bash
# Crontab einrichten (als HA-Benutzer)
crontab -e
# Täglich um 8:00 Uhr:
0 8 * * * /config/radicale_check.sh >> /var/log/radicale_check.log 2>&1
```