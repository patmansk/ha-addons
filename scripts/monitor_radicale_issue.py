#!/usr/bin/env python3
"""
Monitoring-Skript für Kozea/Radicale#2237
Überwacht das GitHub-Issue und aktualisiert bei einer neuen Version/Release
die lokale Radicale-Addon-Konfiguration.
"""

import os
import json
import subprocess
import re
import sys
from datetime import datetime
from pathlib import Path

GITHUB_API = "https://api.github.com"
REPO = "Kozea/Radicale"
ISSUE_NUMBER = 2237
LOCAL_REPO_PATH = Path("/projects/radicale-haos-addon/radicale")
CONFIG_FILE = LOCAL_REPO_PATH / "config.yaml"
DOCKERFILE = LOCAL_REPO_PATH / "Dockerfile"
CHANGELOG_FILE = LOCAL_REPO_PATH / "CHANGELOG.md"
STATE_FILE = Path("/tmp/radicale_monitor_state.json")


def get_github_token():
    token = os.environ.get("GITHUB_PERSONAL_ACCESS_TOKEN")
    if not token:
        print("⚠️  GITHUB_PERSONAL_ACCESS_TOKEN nicht gesetzt!")
        return None
    return token


def get_headers(token):
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "radicale-addon-monitor"
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def check_issue_status(token):
    """Prüft den Status des GitHub-Issues und holt relevante Informationen."""
    import urllib.request
    import urllib.error

    url = f"{GITHUB_API}/repos/{REPO}/issues/{ISSUE_NUMBER}"
    req = urllib.request.Request(url, headers=get_headers(token))

    try:
        with urllib.request.urlopen(req) as response:
            issue_data = json.loads(response.read().decode())
            print(f"✅ Issue {ISSUE_NUMBER} erfolgreich abgerufen")
            print(f"   Titel: {issue_data.get('title', 'N/A')}")
            print(f"   Status: {issue_data.get('state', 'N/A')}")
            print(f"   Zuletzt aktualisiert: {issue_data.get('updated_at', 'N/A')}")

            # Prüfe, ob das Issue geschlossen ist
            if issue_data.get('state') == 'closed':
                print("   🎉 Issue ist geschlossen – mögliche Lösung gefunden!")

            # Hole Kommentare, um nach Release-Versionsnummern zu suchen
            comments_url = f"{GITHUB_API}/repos/{REPO}/issues/{ISSUE_NUMBER}/comments"
            comments_req = urllib.request.Request(comments_url, headers=get_headers(token))
            with urllib.request.urlopen(comments_req) as comments_response:
                comments = json.loads(comments_response.read().decode())

            print(f"   💬 {len(comments)} Kommentare gefunden")

            # Suche nach Versionsnummern in der Issue und Kommentaren
            version_pattern = re.compile(r'\d+\.\d+\.\d+[\w.]*')
            versions_found = set()

            body = issue_data.get('body', '') or ''
            for match in version_pattern.findall(body):
                versions_found.add(match)

            for comment in comments:
                comment_body = comment.get('body', '') or ''
                for match in version_pattern.findall(comment_body):
                    versions_found.add(match)

            if versions_found:
                print(f"   📦 Gefundene Versionen: {', '.join(sorted(versions_found, key=lambda v: [int(x) if x.isdigit() else 0 for x in re.split(r'[.\-]', v)]))}")
            else:
                print("   📭 Keine expliziten Versionsnummern gefunden")

            return issue_data, comments, versions_found

    except urllib.error.HTTPError as e:
        print(f"❌ HTTP-Fehler bei Issue-Abfrage: {e.code} {e.reason}")
        return None, [], set()
    except Exception as e:
        print(f"❌ Fehler bei Issue-Abfrage: {str(e)}")
        return None, [], set()


def check_latest_release(token):
    """Holt die neueste Release-Version von Radicale."""
    import urllib.request
    import urllib.error

    url = f"{GITHUB_API}/repos/{REPO}/releases/latest"
    req = urllib.request.Request(url, headers=get_headers(token))

    try:
        with urllib.request.urlopen(req) as response:
            release_data = json.loads(response.read().decode())
            tag = release_data.get('tag_name', '')
            version = tag.replace('v', '')
            print(f"✅ Neueste Release-Version: {version}")
            print(f"   Veröffentlicht am: {release_data.get('published_at', 'N/A')}")
            return version
    except urllib.error.HTTPError as e:
        print(f"❌ HTTP-Fehler bei Release-Abfrage: {e.code} {e.reason}")
        return None
    except Exception as e:
        print(f"❌ Fehler bei Release-Abfrage: {str(e)}")
        return None


def get_current_version():
    """Liest die aktuelle Version aus config.yaml."""
    try:
        content = CONFIG_FILE.read_text()
        match = re.search(r'version:\s*["\']?([^"\'\s]+)["\']?', content)
        if match:
            return match.group(1)
    except Exception as e:
        print(f"❌ Fehler beim Lesen der aktuellen Version: {str(e)}")
    return None


def update_config(new_version):
    """Aktualisiert die Konfigurationsdateien mit der neuen Version."""
    print(f"\n🔄 Aktualisiere Konfiguration auf Version {new_version}...")

    # 1. Update config.yaml
    try:
        content = CONFIG_FILE.read_text()
        updated_content = re.sub(
            r'version:\s*["\']?[^"\'\s]+["\']?',
            f'version: "{new_version}"',
            content
        )
        CONFIG_FILE.write_text(updated_content)
        print(f"   ✅ config.yaml aktualisiert auf {new_version}")
    except Exception as e:
        print(f"   ❌ Fehler beim Update von config.yaml: {str(e)}")
        return False

    # 2. Update Dockerfile (pip install Version)
    try:
        dockerfile_content = DOCKERFILE.read_text()
        # Ersetze die aktuelle radicale-Version im pip install Befehl
        updated_dockerfile = re.sub(
            r'radicale==[\d.]+[\w.]*',
            f'radicale=={new_version}',
            dockerfile_content
        )
        if updated_dockerfile != dockerfile_content:
            DOCKERFILE.write_text(updated_dockerfile)
            print(f"   ✅ Dockerfile aktualisiert auf Radicale {new_version}")
        else:
            print(f"   ℹ️  Dockerfile konnte nicht aktualisiert werden (Muster nicht gefunden)")
    except Exception as e:
        print(f"   ❌ Fehler beim Update von Dockerfile: {str(e)}")
        return False

    # 3. Update CHANGELOG.md
    try:
        changelog_content = CHANGELOG_FILE.read_text()

        # Füge einen neuen Eintrag oben hinzu (nach dem Titel)
        timestamp = datetime.now().strftime("%Y-%m-%d")
        new_entry = f"\n## {new_version}\n\n- Automatische Aktualisierung durch Monitoring von Kozea/Radicale#2237\n- Neue Version erkannt und Konfiguration angepasst\n- Datum: {timestamp}\n"

        # Einfügen nach der ersten Zeile (# Changelog)
        lines = changelog_content.split('\n')
        insert_index = 2  # Nach "# Changelog" und leerer Zeile
        lines.insert(insert_index, new_entry.strip())

        CHANGELOG_FILE.write_text('\n'.join(lines))
        print(f"   ✅ CHANGELOG.md aktualisiert")
    except Exception as e:
        print(f"   ❌ Fehler beim Update von CHANGELOG.md: {str(e)}")
        return False

    return True


def save_state(data):
    """Speichert den aktuellen Zustand für die nächste Ausführung."""
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(STATE_FILE, 'w') as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print(f"⚠️  Warnung: Zustand konnte nicht gespeichert werden: {str(e)}")


def load_state():
    """Lädt den zuletzt gespeicherten Zustand."""
    try:
        if STATE_FILE.exists():
            with open(STATE_FILE) as f:
                return json.load(f)
    except Exception as e:
        print(f"⚠️  Warnung: Zustand konnte nicht geladen werden: {str(e)}")
    return None


def main():
    print("=" * 60)
    print("Radicale Issue #2237 Monitor")
    print("=" * 60)
    print(f"⏰ Zeitstempel: {datetime.now().isoformat()}\n")

    token = get_github_token()

    # Prüfe die aktuelle Version
    current_version = get_current_version()
    print(f"📌 Aktuelle lokale Version: {current_version or 'Unbekannt'}\n")

    # Hole das neueste Release
    latest_release = check_latest_release(token)
    if not latest_release:
        print("\n❌ Konnte keine neue Release-Version ermitteln. Beende.")
        return 1

    # Prüfe das Issue
    issue_data, comments, versions_found = check_issue_status(token)

    # Bestimme die Zielversion
    # Strategie: Wenn das Issue geschlossen ist oder eine Version in den Kommentaren
    # höher ist als die aktuelle, nutze die höchste gefundene Version
    target_version = latest_release

    if versions_found:
        # Finde die höchste Version aus den gefundenen
        def version_key(v):
            parts = re.split(r'[.\-]', v)
            return [int(p) if p.isdigit() else 0 for p in parts]

        sorted_versions = sorted(versions_found, key=version_key, reverse=True)
        highest_issue_version = sorted_versions[0]

        # Vergleiche mit dem aktuellen Release
        current_key = [int(p) if p.isdigit() else 0 for p in re.split(r'[.\-]', current_version or '0')]
        issue_key = [int(p) if p.isdigit() else 0 for p in re.split(r'[.\-]', highest_issue_version)]
        release_key = [int(p) if p.isdigit() else 0 for p in re.split(r'[.\-]', latest_release)]

        if issue_key > release_key:
            print(f"\n📊 Höchste Version im Issue: {highest_issue_version}")
            target_version = highest_issue_version
        else:
            print(f"\n📊 Neuestes Release ist neuer als Issue-Versionshinweise")

    # Prüfe ob Update nötig ist
    current_key = [int(p) if p.isdigit() else 0 for p in re.split(r'[.\-]', current_version or '0')]
    target_key = [int(p) if p.isdigit() else 0 for p in re.split(r'[.\-]', target_version)]

    if target_key <= current_key:
        print(f"\n✅ Lokale Version ({current_version}) ist aktuell oder neuer. Kein Update nötig.")
        save_state({
            "last_check": datetime.now().isoformat(),
            "current_version": current_version,
            "target_version": target_version,
            "action": "no_update_needed"
        })
        return 0

    print(f"\n🚀 Update von {current_version} → {target_version} erforderlich!\n")

    # Führe das Update aus
    success = update_config(target_version)

    if success:
        print("\n" + "=" * 60)
        print("✅ Update erfolgreich abgeschlossen!")
        print("=" * 60)

        # Zeige diff an
        try:
            subprocess.run(["git", "diff"], cwd="/projects/radicale-haos-addon", check=False)
        except:
            pass

        print("\n💡 Nächste Schritte:")
        print("   1. Prüfe die Änderungen mit `git diff`")
        print("   2. Teste das Add-on lokal")
        print("   3. Push die Änderungen mit `git push origin main`")
        print("      (oder nutze das GitHub API-Skript)")

        save_state({
            "last_check": datetime.now().isoformat(),
            "previous_version": current_version,
            "new_version": target_version,
            "action": "updated"
        })
    else:
        print("\n❌ Update fehlgeschlagen!")
        save_state({
            "last_check": datetime.now().isoformat(),
            "action": "update_failed"
        })
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())