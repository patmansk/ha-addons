# Scripts

Hilfsprogramme und Automationen für das Radicale-Add-on.

## Monitoring: Kozea/Radicale#2237

Das Skript `monitor_radicale_issue.py` überwacht das GitHub-Issue [Kozea/Radicale#2237](https://github.com/Kozea/Radicale/issues/2237) und aktualisiert bei Bedarf die lokale Add-on-Konfiguration.

### Funktionsweise

1. **Prüft das neueste Radicale-Release** über die GitHub API.
2. **Analysiert das Issue #2237** und dessen Kommentare auf Versionshinweise.
3. **Vergleicht** die gefundene Version mit der aktuellen lokalen Version in `config.yaml`.
4. **Aktualisiert bei Bedarf**:
   - `config.yaml` (Version)
   - `Dockerfile` (pip-install-Version)
   - `CHANGELOG.md` (neuer Eintrag)

### Ausführung

```bash
# Manuelle Ausführung
python3 scripts/monitor_radicale_issue.py

# Setup für automatische Ausführung (Cron/Systemd)
bash scripts/setup_monitor_cron.sh
```

### Voraussetzungen

- `GITHUB_PERSONAL_ACCESS_TOKEN` als Umgebungsvariable gesetzt
- Python 3.6+
- Zugriff auf GitHub API

### Zustandsverwaltung

Das Skript speichert seinen Zustand in `/tmp/radicale_monitor_state.json`, um wiederholte Updates derselben Version zu vermeiden.