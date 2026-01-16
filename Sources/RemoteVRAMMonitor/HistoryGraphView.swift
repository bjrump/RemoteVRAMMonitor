import SwiftUI
import Charts

struct HistoryGraphView: View {
    let history: [VRAMMonitor.GPUHistoryPoint]
    let gpuIndex: Int
    @Binding var timeWindow: TimeWindow
    var onHover: ((Bool) -> Void)?
    
    var filteredHistory: [VRAMMonitor.GPUHistoryPoint] {
        let cutoff = Date().addingTimeInterval(-timeWindow.duration)
        return history.filter { $0.date >= cutoff }
    }
    
    var maxUsageInWindow: Int {
        let max = filteredHistory.map(\.memoryUsagePercent).max() ?? 100
        // Ensure we at least show up to 10% if usage is very low, and round up to nearest 10
        return Swift.max(10, ((max + 9) / 10) * 10)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GPU \(gpuIndex) Usage History")
                    .font(.headline)
                Spacer()
                Picker("Time", selection: $timeWindow) {
                    ForEach(TimeWindow.allCases) { window in
                        Text(window.rawValue).tag(window)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)
            }
            
            if filteredHistory.isEmpty {
                VStack {
                    Spacer()
                    Text("No data for this time period")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(height: 160)
            } else {
                Chart(filteredHistory) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Memory", point.memoryUsagePercent)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.monotone)
                    
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Memory", point.memoryUsagePercent)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                }
                .chartYScale(domain: 0...maxUsageInWindow)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 160)
            }
        }
        .padding()
        .frame(width: 450, height: 250)
        .onHover { isHovering in
            onHover?(isHovering)
        }
    }
}
