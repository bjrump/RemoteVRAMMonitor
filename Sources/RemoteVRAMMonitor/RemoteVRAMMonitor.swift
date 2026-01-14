import SwiftUI

@main
struct RemoteVRAMMonitorApp: App {
    @StateObject private var monitor = VRAMMonitor()
    
    var iconName: String {
        if monitor.lastError != nil {
            return "exclamationmark.triangle"
        } else if !monitor.isConnected && monitor.gpus.isEmpty {
            return "network.slash"
        } else {
            return "memorychip"
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            if let error = monitor.lastError {
                Text("Status: Error")
                Text(error).font(.caption).foregroundColor(.red)
                Divider()
            } else if monitor.gpus.isEmpty {
                 Text("Status: Connecting...")
            }
            
            ForEach(monitor.gpus) { gpu in
                let usedGB = String(format: "%.1f", Double(gpu.memoryUsed) / 1024.0)
                let totalGB = String(format: "%.0f", Double(gpu.memoryTotal) / 1024.0)
                
                Button(action: {}) {
                    Text("GPU \(gpu.index):  Mem \(gpu.usagePercentage)% (\(usedGB)/\(totalGB) GB)  |  Util \(gpu.gpuUtilization)%")
                }
            }
            
            Divider()
            
            Button("Refresh") {
                Task {
                    await monitor.refresh()
                }
            }
            
            Divider()
            
            if #available(macOS 14.0, *) {
                SettingsLink {
                    Text("Settings")
                }
            } else {
                Button("Settings") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            if monitor.gpus.count > 0 {
                Image(nsImage: renderIcon(gpus: monitor.gpus))
            } else {
                Image(systemName: iconName)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        
        Settings {
            SettingsView(monitor: monitor)
        }
    }
    
    @MainActor
    func renderIcon(gpus: [GPUInfo]) -> NSImage {
        let view = CompactGPUGridView(gpus: gpus)
            .padding(2)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        
        renderer.isOpaque = false
        
        return renderer.nsImage ?? NSImage(systemSymbolName: "memorychip", accessibilityDescription: nil)!
    }
}

struct CompactGPUGridView: View {
    let gpus: [GPUInfo]
    
    var body: some View {
        VStack(spacing: -1) {
            HStack(spacing: 0) {
                ForEach(0..<min(4, gpus.count), id: \.self) { i in
                    UsageText(percentage: gpus[i].usagePercentage)
                }
            }
            if gpus.count > 4 {
                HStack(spacing: 0) {
                    ForEach(4..<min(8, gpus.count), id: \.self) { i in
                        UsageText(percentage: gpus[i].usagePercentage)
                    }
                }
            }
        }
    }
}

struct UsageText: View {
    let percentage: Int
    
    var color: Color {
        if percentage > 75 { return .red }
        if percentage > 50 { return .orange }
        return .white
    }
    
    var body: some View {
        Text("\(percentage)")
            .font(.system(size: 7, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .frame(width: 14, alignment: .center)
            .fixedSize()
    }
}

struct SettingsView: View {
    @ObservedObject var monitor: VRAMMonitor
    @State private var user: String = ""
    @State private var host: String = ""
    @State private var showDebug: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("SSH Connection")) {
                TextField("User", text: $user)
                TextField("Host", text: $host)
            }
            
            if let error = monitor.lastError {
                 Section(header: Text("Last Error")) {
                     Text(error)
                         .foregroundColor(.red)
                         .textSelection(.enabled)
                 }
            }
            
            Section {
                 Toggle("Show Raw SSH Output", isOn: $showDebug)
            }
            
            if showDebug {
                Section(header: Text("Raw Output")) {
                    Text(monitor.lastRawOutput.isEmpty ? "No Data" : monitor.lastRawOutput)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxHeight: 100)
                }
            }
            
            Text("Changes are saved immediately but require a refresh.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                Button("Save & Refresh") {
                    monitor.updateConfig(user: user, host: host)
                }
            }
        }
        .padding()
        .frame(width: 450, height: showDebug ? 500 : 300)
        .onAppear {
            user = monitor.config.user
            host = monitor.config.host
        }
    }
}
