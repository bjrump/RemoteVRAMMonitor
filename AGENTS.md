# AGENTS.md

This file provides context for AI coding assistants working on this project.

## Project Overview

**RemoteVRAMMonitor** is a macOS menu bar application that monitors GPU memory usage on remote servers via SSH. It's built with Swift and SwiftUI.

## Architecture

| File | Purpose |
|------|---------|
| `RemoteVRAMMonitor.swift` | Main SwiftUI app entry point, menu bar UI, settings view |
| `VRAMMonitor.swift` | Observable state manager, handles polling timer and refresh logic |
| `SSHClient.swift` | Actor that executes SSH commands and parses nvidia-smi output |
| `Configuration.swift` | Codable config struct, handles loading/saving to JSON file |

## Key Design Decisions

### SSH Connection
- Uses system `/usr/bin/ssh` via `Process` – no third-party SSH libraries
- Connection multiplexing via `ControlMaster` to reduce connection overhead
- Socket stored at `/tmp/vram_{user}_{host}.sock`

### Server Command
The only command executed on remote servers:
```bash
nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits
```
This is intentionally minimal and read-only for security compliance.

### Concurrency
- `SSHClient` is an `actor` to ensure thread-safe SSH operations
- `VRAMMonitor` is `@MainActor` for UI state updates
- Polling uses `Timer` with async Task dispatch

## Build Instructions

```bash
# Build and create .app bundle
./create_app.sh

# Manual build only
swift build -c release
```

## Configuration

User settings stored at `~/.remote_vram_config.json`:
```json
{
  "user": "username",
  "host": "server.example.com"
}
```

## Common Tasks

### Adding a new GPU metric
1. Update the `nvidia-smi` query in `SSHClient.swift` line 33
2. Add the field to `GPUInfo` struct in `SSHClient.swift`
3. Update `parseOutput()` to extract the new field
4. Display it in `RemoteVRAMMonitor.swift` UI

### Changing polling interval
- Modify the `Timer` interval in `VRAMMonitor.swift` line 38 (currently 5.0 seconds)

### Changing SSH timeout
- Modify `ConnectTimeout` in `SSHClient.swift` line 36 (currently 5 seconds)

## Testing

Currently no automated tests. Manual testing:
1. Build with `./create_app.sh`
2. Run the app
3. Configure SSH settings
4. Verify GPU data appears in menu bar

## Dependencies

None – the project uses only Apple frameworks:
- SwiftUI
- Foundation

## Platform Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+
