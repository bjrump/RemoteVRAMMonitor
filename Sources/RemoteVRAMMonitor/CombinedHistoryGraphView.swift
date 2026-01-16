import SwiftUI
import Charts

struct CombinedHistoryGraphView: View {
    let history: [Int: [VRAMMonitor.GPUHistoryPoint]]
    @Binding var timeWindow: TimeWindow
    var onHover: ((Bool) -> Void)?
    
    @State private var selectedDate: Date?
    
    var referenceHistory: [VRAMMonitor.GPUHistoryPoint] {
        guard let firstKey = sortedHistoryIndices.first,
              let points = history[firstKey] else { return [] }
        let cutoff = Date().addingTimeInterval(-timeWindow.duration)
        return points.filter { $0.date >= cutoff }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Memory Usage")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                memoryChart
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("GPU Utilization")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                utilizationChart
            }
        }
        .padding()
        .frame(width: 500, height: 450)
        .onHover { isHovering in
            onHover?(isHovering)
        }
    }
    
    var header: some View {
        HStack {
            Text("All GPUs Usage History")
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
    }
    
    var memoryChart: some View {
        Chart {
            ForEach(sortedHistoryIndices, id: \.self) { index in
                if let points = history[index] {
                    let filteredPoints = points.filter { $0.date >= cutoffDate }
                    let displayPoints = filteredPoints.downsampled(to: 200)
                    
                    ForEach(displayPoints) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Memory", point.memoryUsagePercent)
                        )
                        .foregroundStyle(by: .value("GPU", "GPU \(index)"))
                        .interpolationMethod(.monotone)
                    }
                    
                    if let selectedDate = selectedDate,
                       let closest = filteredPoints.binarySearch(for: selectedDate) {
                        
                        RuleMark(x: .value("Selected", selectedDate))
                            .foregroundStyle(.gray.opacity(0.5))
                        
                        PointMark(
                            x: .value("Selected", closest.date),
                            y: .value("Value", closest.memoryUsagePercent)
                        )
                        .foregroundStyle(by: .value("GPU", "GPU \(index)"))
                    }
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis { AxisMarks(position: .leading) }
        .chartForegroundStyleScale(range: gpuColors)
        .chartOverlay { proxy in
            sharedChartOverlay(proxy: proxy)
        }
        .frame(height: 150)
    }
    
    var utilizationChart: some View {
        Chart {
            ForEach(sortedHistoryIndices, id: \.self) { index in
                if let points = history[index] {
                    let filteredPoints = points.filter { $0.date >= cutoffDate }
                    let displayPoints = filteredPoints.downsampled(to: 200)
                    
                    ForEach(displayPoints) { point in
                        LineMark(
                            x: .value("Time", point.date),
                            y: .value("Utilization", point.utilization)
                        )
                        .foregroundStyle(by: .value("GPU", "GPU \(index)"))
                        .interpolationMethod(.monotone)
                    }

                    
                    if let selectedDate = selectedDate,

                       let closest = filteredPoints.binarySearch(for: selectedDate) {
                        
                        RuleMark(x: .value("Selected", selectedDate))
                            .foregroundStyle(.gray.opacity(0.5))
                        
                        PointMark(
                            x: .value("Selected", closest.date),
                            y: .value("Value", closest.utilization)
                        )
                        .foregroundStyle(by: .value("GPU", "GPU \(index)"))
                    }
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis { AxisMarks(position: .leading) }
        .chartForegroundStyleScale(range: gpuColors)
        .chartOverlay { proxy in
            sharedChartOverlay(proxy: proxy)
        }
        .frame(height: 150)
    }
    
    @ViewBuilder
    func sharedChartOverlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .onContinuousHover(coordinateSpace: .local) { phase in
                    switch phase {
                    case .active(let location):
                        guard let date: Date = proxy.value(atX: location.x) else {
                            selectedDate = nil
                            return
                        }
                        
                        if let closest = referenceHistory.binarySearch(for: date) {
                            selectedDate = closest.date
                        } else {
                            selectedDate = nil
                        }
                    case .ended:
                        selectedDate = nil
                    }
                }
            
            if let selectedDate = selectedDate,
               let xPosition = proxy.position(forX: selectedDate) {
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedDate.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                    
                    ForEach(sortedHistoryIndices, id: \.self) { gpuIdx in
                        if let gpuPoints = history[gpuIdx] {
                            let gpuFiltered = gpuPoints.filter { $0.date >= cutoffDate }
                            if let gpuClosest = gpuFiltered.binarySearch(for: selectedDate) {
                                HStack {
                                    Text("GPU \(gpuIdx):")
                                        .font(.caption2)
                                    Text("M: \(gpuClosest.memoryUsagePercent)%")
                                        .font(.caption2)
                                        .bold()
                                    Text("U: \(gpuClosest.utilization)%")
                                        .font(.caption2)
                                        .bold()
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(6)
                .background(Material.regular)
                .cornerRadius(4)
                .shadow(radius: 2)
                .position(x: xPosition, y: 75)
            }
        }
    }
    
    var sortedHistoryIndices: [Int] {
        history.keys.sorted()
    }
    
    var cutoffDate: Date {
        Date().addingTimeInterval(-timeWindow.duration)
    }
    
    var gpuColors: [Color] {
        [
            Color.blue, Color.green, Color.orange, Color.purple,
            Color.red, Color.cyan, Color.pink, Color.yellow
        ]
    }
}
