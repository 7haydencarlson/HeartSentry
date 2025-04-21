import SwiftUI

struct MeasurementChartView: View {
    var measurementName: String
    @State private var measurementData: [(time: Double, weight: Double, heartRate: Double)] = [] // Assuming data consists of time, weight, heart rate tuples
    
    var storage = StoreEvalData()  // Access your new data storage class

    var body: some View {
        VStack {
            if measurementData.isEmpty {
                Text("No data available")
                    .font(.headline)
                    .foregroundColor(.gray)
            } else {
                List(measurementData, id: \.time) { dataPoint in
                    VStack(alignment: .leading) {
                        Text("Time: \(dataPoint.time, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("Weight: \(dataPoint.weight, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Heart Rate: \(dataPoint.heartRate, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadMeasurementData()
        }
        .navigationTitle("Measurement Data")
    }

    private func loadMeasurementData() {
        // Assuming StoreEvalData has a method like `loadMeasurementData` that returns a list of tuples (time, weight, heart rate)
        if let data = storage.loadMeasurementData(named: measurementName) {
            DispatchQueue.main.async {
                print("Loaded data: \(data)")  // Log the loaded data
                measurementData = data
            }
        } else {
            print("Failed to load data for measurement: \(measurementName)")
        }
    }
}
