# Remote VRAM Monitor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-macOS-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)

A lightweight macOS menu bar app that displays real-time GPU memory usage from
remote servers via SSH.

<img width="75" height="30" alt="Screenshot 2026-01-14 at 15 14 05" src="https://github.com/user-attachments/assets/45ea9e57-a4dd-4a46-ad29-0b62b6290aa0" />

## Features

- 📊 **Real-time monitoring** – GPU memory and utilization updated every 5
  seconds
- 🖥️ **Multi-GPU support** – Monitor up to 8 GPUs simultaneously in the menu bar
- 🔒 **Secure** – Uses your existing SSH keys, no passwords stored
- ⚡ **Lightweight** – Minimal resource usage with SSH connection multiplexing
- 🎨 **Color-coded** – Quick visual feedback (white/orange/red based on usage)

## What Runs on the Server

The app executes only one read-only command via SSH:

```bash
nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits
```

This returns only numeric GPU statistics (memory in MB, utilization in %). No
sensitive data, no file access, no system modifications.

## Requirements

- **macOS 13.0** (Ventura) or later
- **SSH access** to your server (key-based authentication recommended)
- **nvidia-smi** installed on the remote server

## Installation

### From Source

1. Clone the repository:

   ```bash
   git clone https://github.com/bjrump/RemoteVRAMMonitor.git
   cd RemoteVRAMMonitor
   ```

2. Build and create the app bundle:

   ```bash
   ./create_app.sh
   ```

3. Move `RemoteVRAMMonitor.app` to your Applications folder.

## Configuration

1. Launch the app – you'll see a menu bar icon
2. Click the icon and select **Settings** (or press `⌘,`)
3. Enter your SSH username and hostname
4. Click **Save & Refresh**

### SSH Key Setup

If you haven't set up SSH keys yet:

```bash
# Generate a key (if you don't have one)
ssh-keygen -t ed25519

# Copy your key to the server
ssh-copy-id user@your-server.com
```

## Architecture

```
Sources/RemoteVRAMMonitor/
├── RemoteVRAMMonitor.swift  # SwiftUI app, menu bar UI, settings view
├── VRAMMonitor.swift        # State management, polling timer
├── SSHClient.swift          # SSH connection, nvidia-smi parsing
└── Configuration.swift      # User settings persistence
```

## Technical Details

- **Polling interval:** 5 seconds
- **SSH multiplexing:** Connections persist for 5 minutes to reduce overhead
- **Config location:** `~/.remote_vram_config.json`

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file
for details.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
