import SwiftUI
import Charts

struct HistoryGraphView: View {
    let history: [VRAMMonitor.GPUHistoryPoint]
    let gpuIndex: Int
    @Binding var timeWindow: TimeWindow
    var onHover: ((Bool) -> Void)?
    
    @State private var selectedPoint: VRAMMonitor.GPUHistoryPoint?
    
    var filteredHistory: [VRAMMonitor.GPUHistoryPoint] {
        let cutoff = Date().addingTimeInterval(-timeWindow.duration)
        return history.filter { $0.date >= cutoff }
    }
    
    var displayHistory: [VRAMMonitor.GPUHistoryPoint] {
        filteredHistory.downsampled(to: 200)
    }
    
    var maxUsageInWindow: Int {
        let max = filteredHistory.map(\.memoryUsagePercent).max() ?? 100
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
                .frame(height: 350)
            } else {
                // Memory Chart
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory Usage")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Chart(displayHistory) { point in
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
                        
                        if let selectedPoint = selectedPoint {
                            RuleMark(x: .value("Selected", selectedPoint.date))
                                .foregroundStyle(.gray.opacity(0.5))
                            
                            PointMark(
                                x: .value("Selected", selectedPoint.date),
                                y: .value("Value", selectedPoint.memoryUsagePercent)
                            )
                            .foregroundStyle(.blue)
                        }
                    }
                    .chartYScale(domain: 0...maxUsageInWindow)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .chartOverlay { proxy in
                        chartOverlay(proxy: proxy, valueProvider: { point in
                            "\(point.memoryUsagePercent)%"
                        })
                    }
                    .frame(height: 150)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("GPU Utilization")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Chart(displayHistory) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Utilization", point.utilization)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.monotone)
                        
                        AreaMark(
                            x: .value("Time", point.date),
                            y: .value("Utilization", point.utilization)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green.opacity(0.3), .green.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)
                        
                        if let selectedPoint = selectedPoint {
                            RuleMark(x: .value("Selected", selectedPoint.date))
                                .foregroundStyle(.gray.opacity(0.5))
                            
                            PointMark(
                                x: .value("Selected", selectedPoint.date),
                                y: .value("Value", selectedPoint.utilization)
                            )
                            .foregroundStyle(.green)
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .chartOverlay { proxy in
                        chartOverlay(proxy: proxy, valueProvider: { point in
                            "\(point.utilization)%"
                        })
                    }
                    .frame(height: 150)
                }
            }
        }
        .padding()
        .frame(width: 450, height: 450)
        .onHover { isHovering in
            onHover?(isHovering)
        }
    }
    
    @ViewBuilder
    func chartOverlay(proxy: ChartProxy, valueProvider: @escaping (VRAMMonitor.GPUHistoryPoint) -> String) -> some View {
        GeometryReader { geometry in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .onContinuousHover(coordinateSpace: .local) { phase in
                    switch phase {
                    case .active(let location):
                        guard let date: Date = proxy.value(atX: location.x) else {
                            selectedPoint = nil
                            return
                        }
                        selectedPoint = filteredHistory.binarySearch(for: date)
                    case .ended:
                        selectedPoint = nil
                    }
                }
            
            if let selectedPoint = selectedPoint,
               let xPosition = proxy.position(forX: selectedPoint.date) {
                
                VStack(spacing: 4) {
                    Text("\(selectedPoint.date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(valueProvider(selectedPoint))
                        .font(.caption)
                        .bold()
                }
                .padding(6)
                .background(Material.regular)
                .cornerRadius(4)
                .shadow(radius: 2)
                .position(x: xPosition, y: 30)
            }
        }
    }
}
