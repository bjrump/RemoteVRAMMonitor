import Foundation

extension RandomAccessCollection where Element == VRAMMonitor.GPUHistoryPoint, Index == Int {
    func downsampled(to limit: Int) -> [Element] {
        if count <= limit {
            return Array(self)
        }
        
        let chunkSize = Double(count) / Double(limit)
        var result: [Element] = []
        result.reserveCapacity(limit)
        
        for i in 0..<limit {
            let start = Int(Double(i) * chunkSize)
            let end = Swift.min(Int(Double(i + 1) * chunkSize), count)
            
            if start < end {
                let chunk = self[start..<end]
                if let maxPoint = chunk.max(by: { $0.memoryUsage < $1.memoryUsage }) {
                    result.append(maxPoint)
                }
            }
        }
        
        return result
    }
    
    func binarySearch(for date: Date) -> Element? {
        guard !isEmpty else { return nil }
        
        var low = startIndex
        var high = endIndex - 1
        
        while low <= high {
            let mid = low + (high - low) / 2
            if self[mid].date < date {
                low = mid + 1
            } else if self[mid].date > date {
                high = mid - 1
            } else {
                return self[mid]
            }
        }
        
        if low >= endIndex {
            return self[endIndex - 1]
        }
        if low <= startIndex {
            return self[startIndex]
        }
        
        let before = self[low - 1]
        let after = self[low]
        
        if abs(before.date.timeIntervalSince(date)) < abs(after.date.timeIntervalSince(date)) {
            return before
        } else {
            return after
        }
    }
}
