# Remote VRAM Monitor

Ein einfaches Mac Menu Bar Tool, um die VRAM-Auslastung von Grafikkarten auf einem entfernten Server anzuzeigen.

## Funktionen
- Zeigt die VRAM-Auslastung (in %) von allen Grafikkarten in der Menu Bar an.
- Nutzt `ssh` und `nvidia-smi` (keine Installation auf dem Server nötig).
- Konfigurierbarer SSH Host und User.

## Voraussetzungen
- SSH-Zugang zum Server (am besten mit SSH Key, damit kein Passwort eingegeben werden muss).
- `nvidia-smi` muss auf dem Server installiert und im PATH verfügbar sein.

## Installation

1. Terminal öffnen.
2. Projekt kompilieren und App erstellen:
   ```bash
   ./create_app.sh
   ```
3. Die erstellte `RemoteVRAMMonitor.app` in den "Programme"-Ordner verschieben.

## Konfiguration

1. Starte die App.
2. In der Menu Bar steht zunächst "Setup Required".
3. Klicke darauf und wähle "Settings" (oder drücke Cmd+,).
4. Gib deinen SSH User und Hostnamen ein (z.B. `benediktrump` und `myserver.local`).
5. Klicke "Save & Refresh".

## Hinweise
- Die App aktualisiert sich alle 5 Sekunden.
- Wenn `ssh` ein Passwort benötigt, funktioniert die App nicht korrekt. Richte SSH Keys ein (`ssh-copy-id user@host`).
