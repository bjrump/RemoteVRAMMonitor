import SwiftUI

@main
struct RemoteVRAMMonitorApp: App {
    @StateObject private var monitor = VRAMMonitor()
    @State private var hoveredGPUIndex: Int?
    
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
            ContentView(monitor: monitor, hoveredGPUIndex: $hoveredGPUIndex)
        } label: {
            if monitor.gpus.count > 0 {
                Image(nsImage: renderIcon(gpus: monitor.gpus))
            } else {
                Image(systemName: iconName)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .menuBarExtraStyle(.window)
        
        WindowGroup("Settings", id: "settings") {
            SettingsView(monitor: monitor)
                .frame(minWidth: 450, minHeight: 300)
        }
        .windowResizability(.contentSize)
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

struct ContentView: View {
    @ObservedObject var monitor: VRAMMonitor
    @Binding var hoveredGPUIndex: Int?
    @State private var hoverTask: Task<Void, Never>?
    @Environment(\.openWindow) var openWindow
    
    func handleHover(isHovering: Bool, index: Int) {
        if isHovering {
            hoverTask?.cancel()
            hoverTask = nil
            hoveredGPUIndex = index
        } else {
            hoverTask?.cancel()
            hoverTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                if !Task.isCancelled {
                    hoveredGPUIndex = nil
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = monitor.lastError {
                VStack(alignment: .leading) {
                    Text("Status: Error")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal)
                Divider()
            } else if monitor.gpus.isEmpty {
                Text("Status: Connecting...")
                    .padding(.horizontal)
                Divider()
            }
            
            ForEach(monitor.gpus) { gpu in
                GPURow(gpu: gpu)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(hoveredGPUIndex == gpu.index ? Color.secondary.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    .onHover { isHovering in
                        handleHover(isHovering: isHovering, index: gpu.index)
                    }
                    .popover(isPresented: Binding(
                        get: { hoveredGPUIndex == gpu.index },
                        set: { _ in }
                    ), arrowEdge: .trailing) {
                        HistoryGraphView(
                            history: monitor.history[gpu.index] ?? [],
                            gpuIndex: gpu.index,
                            onHover: { isHovering in
                                handleHover(isHovering: isHovering, index: gpu.index)
                            }
                        )
                    }
            }
            
            if !monitor.gpus.isEmpty {
                Divider()
            }
            
            HStack {
                Button("Refresh") {
                    Task {
                        await monitor.refresh()
                    }
                }
                
                Spacer()
                
                Button("Settings") {
                    openWindow(id: "settings")
                    NSApp.activate(ignoringOtherApps: true)
                }
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct GPURow: View {
    let gpu: GPUInfo
    
    var body: some View {
        let usedGB = String(format: "%.1f", Double(gpu.memoryUsed) / 1024.0)
        let totalGB = String(format: "%.0f", Double(gpu.memoryTotal) / 1024.0)
        
        VStack(alignment: .leading, spacing: 2) {
            Text("GPU \(gpu.index)")
                .font(.headline)
            HStack {
                Text("Mem: \(gpu.usagePercentage)%")
                    .foregroundColor(gpu.usagePercentage > 75 ? .red : (gpu.usagePercentage > 50 ? .orange : .primary))
                Text("(\(usedGB)/\(totalGB) GB)")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Util: \(gpu.gpuUtilization)%")
            }
            .font(.caption)
        }
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
