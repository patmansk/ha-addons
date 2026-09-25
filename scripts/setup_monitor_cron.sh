#!/bin/bash
# Setup-Skript für die automatische Überwachung von Kozea/Radicale#2237
# Erstellt einen Cron-Job, der das Monitoring-Skript regelmäßig ausführt.

CRON_FILE="/tmp/radicale_monitor_cron"
SCRIPT_PATH="/projects/radicale-haos-addon/scripts/monitor_radicale_issue.py"
LOG_FILE="/tmp/radicale_monitor.log"
PYTHON_BIN="/usr/local/bin/python3"

echo "📋 Konfiguriere Cron-Job für Radicale Issue Monitor..."
echo ""

# Prüfe, ob cron installiert ist
if ! command -v crontab &> /dev/null; then
    echo "⚠️  crontab ist nicht verfügbar. Versuche systemd timer..."
    
    # Erstelle einen systemd timer als Alternative
    TIMER_FILE="/etc/systemd/system/radicale-monitor.timer"
    SERVICE_FILE="/etc/systemd/system/radicale-monitor.service"
    
    if [ -w "/etc/systemd/system/" ]; then
        cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Radicale Issue #2237 Monitor
After=network.target

[Service]
Type=oneshot
ExecStart=${PYTHON_BIN} ${SCRIPT_PATH}
User=openhands
EnvironmentFile=/tmp/radicale_monitor.env
EOF

        cat > "$TIMER_FILE" << EOF
[Unit]
Description=Timer for Radicale Issue Monitor

[Timer]
OnBootSec=10min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

        # Erstelle Environment File mit Token
        if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
            echo "GITHUB_PERSONAL_ACCESS_TOKEN=$GITHUB_PERSONAL_ACCESS_TOKEN" > /tmp/radicale_monitor.env
            chmod 600 /tmp/radicale_monitor.env
        fi

        systemctl daemon-reload
        systemctl enable radicale-monitor.timer
        systemctl start radicale-monitor.timer
        
        echo "✅ Systemd Timer eingerichtet!"
        echo "   Status: systemctl status radicale-monitor.timer"
        echo "   Logs: journalctl -u radicale-monitor.service"
    else
        echo "❌ Keine Berechtigung für systemd. Bitte manuell ausführen:"
        echo "   $PYTHON_BIN $SCRIPT_PATH"
    fi
else
    # Verwende Cron
    echo "# Radicale Issue #2237 Monitor - täglich um 08:00 und 18:00" > "$CRON_FILE"
    echo "0 8,18 * * * ${PYTHON_BIN} ${SCRIPT_PATH} >> ${LOG_FILE} 2>&1" >> "$CRON_FILE"
    
    # Füge zu bestehendem crontab hinzu
    if crontab -l > /dev/null 2>&1; then
        crontab -l > /tmp/crontab_backup
        cat "$CRON_FILE" >> /tmp/crontab_new
        crontab /tmp/crontab_new
        rm /tmp/crontab_new
        echo "✅ Cron-Job hinzugefügt zu bestehendem Crontab"
    else
        crontab "$CRON_FILE"
        echo "✅ Cron-Job eingerichtet (neuer Crontab)"
    fi
    
    echo ""
    echo "📊 Cron-Ausführung: Täglich um 08:00 und 18:00 Uhr"
    echo "📝 Log-Datei: $LOG_FILE"
fi

echo ""
echo "============================================================"
echo "✅ Monitoring-Setup abgeschlossen!"
echo "============================================================"
echo ""
echo "Manuelle Ausführung jederzeit mit:"
echo "   $PYTHON_BIN $SCRIPT_PATH"
echo ""
echo "Log-Prüfung:"
echo "   tail -f $LOG_FILE"