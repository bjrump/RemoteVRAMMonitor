import SwiftUI
import Charts

struct CombinedHistoryGraphView: View {
    let history: [Int: [VRAMMonitor.GPUHistoryPoint]]
    @Binding var timeWindow: TimeWindow
    var onHover: ((Bool) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            chart
        }
        .padding()
        .frame(width: 500, height: 290)
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
    
    var chart: some View {
        Chart {
            ForEach(sortedHistoryIndices, id: \.self) { index in
                chartContent(for: index)
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartForegroundStyleScale(range: [
            Color.blue, Color.green, Color.orange, Color.purple,
            Color.red, Color.cyan, Color.pink, Color.yellow
        ])
        .frame(height: 200)
    }
    
    @ChartContentBuilder
    func chartContent(for index: Int) -> some ChartContent {
        if let points = history[index] {
             let filteredPoints = points.filter { $0.date >= cutoffDate }
             ForEach(filteredPoints) { point in
                 LineMark(
                     x: .value("Time", point.date),
                     y: .value("Memory", point.memoryUsagePercent)
                 )
                 .foregroundStyle(by: .value("GPU", "GPU \(index)"))
                 .interpolationMethod(.monotone)
             }
        }
    }
    
    var sortedHistoryIndices: [Int] {
        history.keys.sorted()
    }
    
    var cutoffDate: Date {
        Date().addingTimeInterval(-timeWindow.duration)
    }
}
