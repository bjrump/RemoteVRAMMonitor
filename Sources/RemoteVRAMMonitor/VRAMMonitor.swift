import Foundation
import SwiftUI

enum TimeWindow: String, CaseIterable, Identifiable, Codable {
    case oneMinute = "1m"
    case fiveMinutes = "5m"
    case thirtyMinutes = "30m"
    case eightHours = "8h"
    case oneDay = "1d"
    
    var id: String { rawValue }
    
    var duration: TimeInterval {
        switch self {
        case .oneMinute: return 60
        case .fiveMinutes: return 300
        case .thirtyMinutes: return 1800
        case .eightHours: return 8 * 3600
        case .oneDay: return 24 * 3600
        }
    }
}

@MainActor
class VRAMMonitor: ObservableObject {
    @Published var gpus: [GPUInfo] = []
    @Published var history: [Int: [GPUHistoryPoint]] = [:]
    @Published var config: AppConfig
    @Published var isConnected: Bool = false
    @Published var lastError: String? = nil
    @Published var lastRawOutput: String = ""
    @Published var selectedTimeWindow: TimeWindow = .oneDay {
        didSet {
            if selectedTimeWindow != config.timeWindow {
                config.timeWindow = selectedTimeWindow
                config.save()
            }
        }
    }
    
    private var client: SSHClient
    private var timer: Timer?
    
    var maxUsage: Int {
        gpus.map(\.usagePercentage).max() ?? 0
    }
    
    init() {
        let loadedConfig = AppConfig.load()
        self.config = loadedConfig
        self.selectedTimeWindow = loadedConfig.timeWindow
        self.client = SSHClient(user: loadedConfig.user, host: loadedConfig.host)
        
        startMonitoring()
    }
    
    struct GPUHistoryPoint: Identifiable {
        let id = UUID()
        let date: Date
        let memoryUsage: Int
        let memoryTotal: Int
        let utilization: Int
        
        var memoryUsagePercent: Int {
            guard memoryTotal > 0 else { return 0 }
            return Int((Double(memoryUsage) / Double(memoryTotal)) * 100)
        }
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
            
            let now = Date()
            for gpu in fetchedGpus {
                let point = GPUHistoryPoint(
                    date: now,
                    memoryUsage: gpu.memoryUsed,
                    memoryTotal: gpu.memoryTotal,
                    utilization: gpu.gpuUtilization
                )
                
                if history[gpu.index] == nil {
                    history[gpu.index] = []
                }
                
                history[gpu.index]?.append(point)
                
                let oneDayAgo = now.addingTimeInterval(-86400)
                if let firstIndex = history[gpu.index]?.firstIndex(where: { $0.date >= oneDayAgo }) {
                    if firstIndex > 0 {
                        history[gpu.index]?.removeFirst(firstIndex)
                    }
                }
            }
            
            self.isConnected = true
            self.lastError = nil
        } catch {
            self.isConnected = false
            self.lastError = error.localizedDescription
            self.gpus = []
        }
    }
}
