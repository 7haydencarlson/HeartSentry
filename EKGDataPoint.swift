//
//  EKGDataPoint.swift
//  Heart Sentry
//
//  Created by Hayden Carlson on 3/20/25.
//
import Foundation

struct EKGDataPoint: Identifiable {
    var id: UUID = UUID()  // Unique identifier for each data point
    var time: TimeInterval
    var values: [Double]  // Array to store 4 load cell values + 2 EKG values
}

extension MeasurementView {
    
    public func averageLoadCellValueLast10Seconds() -> Double {
        // Get the current time relative to the start of the measurement
        guard let firstDataPoint = bluetoothManager.ekgData.first else {
            return 0.0
        }
        
        let startTime = firstDataPoint.time // The time at which the measurement started
        
        // Filter out data points from the last 10 seconds (relative to the start time)
        let tenSecondsAgo = startTime + 10.0
        let recentDataPoints = bluetoothManager.ekgData.filter { dataPoint in
            // Only include data points that are within the last 10 seconds
            return dataPoint.time >= tenSecondsAgo
        }
        
        // Extract load cell values (assuming the second index in the `values` array is the load cell)
        let loadCellValues = recentDataPoints.compactMap { dataPoint -> Double? in
            if dataPoint.values.indices.contains(1) {
                return dataPoint.values[1] // Load cell value
            }
            return nil
        }
        
        // If there are any load cell values in the last 10 seconds, calculate the average
        if loadCellValues.isEmpty {
            return 0.0
        } else {
            let sum = loadCellValues.reduce(0.0) { $0 + $1 }
            return sum / Double(loadCellValues.count)
        }
    }
}
