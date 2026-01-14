import Foundation

struct GPUInfo: Identifiable {
    let index: Int
    let memoryUsed: Int
    let memoryTotal: Int
    let gpuUtilization: Int
    
    var id: Int { index }
    
    var usagePercentage: Int {
        guard memoryTotal > 0 else { return 0 }
        return Int((Double(memoryUsed) / Double(memoryTotal)) * 100)
    }
}

actor SSHClient {
    private let host: String
    private let user: String
    private let sshPath = "/usr/bin/ssh"
    
    init(user: String, host: String) {
        self.user = user
        self.host = host
    }
    
    func fetchGPUData() async throws -> (gpus: [GPUInfo], raw: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sshPath)
        
        let socketPath = "/tmp/vram_\(user.prefix(8))_\(host.prefix(10)).sock"
        
        let command = "PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits"
        
        process.arguments = [
            "-o", "ConnectTimeout=5",
            "-o", "ControlMaster=auto",
            "-o", "ControlPath=\(socketPath)",
            "-o", "ControlPersist=5m",
            "\(user)@\(host)",
            command
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "SSHClient", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "SSH command failed"])
        }
        
        guard let output = String(data: data, encoding: .utf8) else {
            return ([], "")
        }
        
        return (parseOutput(output), output)
    }
    
    private func parseOutput(_ output: String) -> [GPUInfo] {
        var gpus: [GPUInfo] = []
        let lines = output.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let parts = line.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 3,
               let used = Int(parts[0]),
               let total = Int(parts[1]),
               let util = Int(parts[2]) {
                gpus.append(GPUInfo(index: index, memoryUsed: used, memoryTotal: total, gpuUtilization: util))
            }
        }
        return gpus
    }
}
