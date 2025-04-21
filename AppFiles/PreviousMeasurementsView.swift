import SwiftUI

struct PreviousMeasurementsView: View {
    @State private var measurements: [String] = []
    private var storage = StoreEvalData() // Assuming this is your custom data storage class

    var body: some View {
        VStack {
            // Display the list of previous measurements
            List(measurements, id: \.self) { measurement in
                NavigationLink(destination: MeasurementChartView(measurementName: measurement)) {
                    Text(measurement)
                }
            }

            // Button to delete all stored measurements
            Button(action: {
                deleteAllMeasurements()
            }) {
                Text("Delete All Measurements")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
                    .padding()
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding()

        }
        .onAppear {
            loadMeasurements()
        }
        .navigationTitle("Previous Measurements")
    }

    // Load measurements from storage
    private func loadMeasurements() {
        measurements = storage.loadAllMeasurementNames() // Assuming this method exists in StoreEvalData
    }

    // Delete all measurements
    private func deleteAllMeasurements() {
        storage.deleteAllData() // Assuming this method exists in StoreEvalData
        loadMeasurements() // Reload the measurements list after deletion
    }
}
