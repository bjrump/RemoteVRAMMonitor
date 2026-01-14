import Foundation
import SwiftUI

@MainActor
class VRAMMonitor: ObservableObject {
    @Published var gpus: [GPUInfo] = []
    @Published var config: AppConfig
    @Published var isConnected: Bool = false
    @Published var lastError: String? = nil
    @Published var lastRawOutput: String = ""
    
    private var client: SSHClient
    private var timer: Timer?
    
    var maxUsage: Int {
        gpus.map(\.usagePercentage).max() ?? 0
    }
    
    init() {
        let loadedConfig = AppConfig.load()
        self.config = loadedConfig
        self.client = SSHClient(user: loadedConfig.user, host: loadedConfig.host)
        
        startMonitoring()
    }
    
    func updateConfig(user: String, host: String) {
        self.config.user = user
        self.config.host = host
        self.config.save()
        self.client = SSHClient(user: user, host: host)
        Task {
            await refresh()
        }
    }
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.refresh()
            }
        }
        Task {
            await refresh()
        }
    }
    
    func refresh() async {
        if config.user == "user" || config.host == "hostname" {
            self.lastError = "Setup Required"
            self.isConnected = false
            return
        }
        
        do {
            let (fetchedGpus, raw) = try await client.fetchGPUData()
            self.gpus = fetchedGpus
            self.lastRawOutput = raw
            self.isConnected = true
            self.lastError = nil
        } catch {
            self.isConnected = false
            self.lastError = error.localizedDescription
            self.gpus = []
        }
    }
}
