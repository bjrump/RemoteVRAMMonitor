import Foundation

struct AppConfig: Codable {
    var user: String
    var host: String
    var timeWindow: TimeWindow = .oneDay
    
    static let defaultPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".remote_vram_config.json")
    
    static func load() -> AppConfig {
        do {
            let data = try Data(contentsOf: defaultPath)
            return try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            return AppConfig(user: "user", host: "hostname", timeWindow: .oneDay)
        }
    }
    
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: AppConfig.defaultPath)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
