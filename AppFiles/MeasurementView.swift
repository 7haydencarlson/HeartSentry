import SwiftUI
import AVKit

struct MeasurementView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager

    @State private var measurementInProgress = false
    @State private var remainingTime: Double = 15.0
    @State private var timer: Timer?
    @State private var isNavigatingToBluetoothView = false
    @State private var goToSurvey = false
    @State private var showSurveyAlert = false // State for the alert popup

    private var storage = StoreEvalData() // Change to use StoreEvalData
    
    private var latestECGValue: Double {
        if let lastDataPoint = bluetoothManager.ekgData.last, lastDataPoint.values.indices.contains(0) {
            return lastDataPoint.values[0]
        }
        return 0.0
    }

    private var latestLoadCellValue: Double {
        // Filter out all load cell values from the ekgData
        let loadCellValues = bluetoothManager.ekgData.compactMap { dataPoint in
            // Ensure there are at least two values and the second value is the load cell value
            if dataPoint.values.indices.contains(1) {
                return dataPoint.values[1]  // Load cell value
            }
            return nil
        }
        
        // Get the last 5 load cell values
        let recentLoadCellValues = loadCellValues.suffix(20)
        
        // Calculate the average if there are any values
        if recentLoadCellValues.isEmpty {
            return 1.0
        } else {
            let sum = recentLoadCellValues.reduce(0.0) { $0 + $1 }
            return sum / Double(recentLoadCellValues.count)
        }
    }

    // Player and looper variables
    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Warning Banner when Bluetooth is not connected to BT05
                    if bluetoothManager.connectionStatus != "Connected to BT05" {
                        VStack(spacing: 10) {
                            Text("⚠️ Please connect to BT05 before proceeding.")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.horizontal)
                            
                            Button(action: {
                                isNavigatingToBluetoothView = true
                            }) {
                                Text("Go to Bluetooth Settings")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .sheet(isPresented: $isNavigatingToBluetoothView) {
                                BluetoothView()
                            }
                        }
                    }

                    VStack(spacing: 8) {
                        Text(bluetoothManager.connectionStatus)
                            .font(.headline)
                            .foregroundColor(bluetoothManager.connectionStatus == "Connected" ? .green : .red)

                        Text("Please step on the scale and place your hand on the pad before beginning the evaluation.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

                    if measurementInProgress {
                        VStack(spacing: 12) {
                            ProgressRing(progress: 1.0 - remainingTime / 15.0, totalTime: 15.0)
                                .padding(.bottom, 10)


                            VStack(spacing: 4) {
                                Text(String(format: "Load Cell (g): %.3f", latestLoadCellValue))
                                    .font(.title3)
                                    .foregroundColor(.green)
                            }

                            Text("Please keep still and rest the pad of your hand on the electrode.")
                                .font(.body)
                                .foregroundColor(.blue)
                                .multilineTextAlignment(.center)
                                .padding(.top)

                            VideoPlayer(player: player)
                                .frame(height: 200)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)))
                    }

                    if !measurementInProgress {
                        Button(action: {
                            startMeasurement()
                        }) {
                            Text("Begin Evaluation")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)
                        .disabled(bluetoothManager.connectionStatus != "Connected to BT05") // Disable until connected
                    }
                }
                .padding()
            }
            .navigationTitle("Evaluation")
            .navigationDestination(isPresented: $goToSurvey) {
                MeasurementSummaryView(weight: latestLoadCellValue)
            }

            .onAppear {
                setupPlayer()
            }
        }
    }

    private func startMeasurement() {
        if let txCharacteristic = bluetoothManager.txCharacteristic {
            let startCommand = "START\n".data(using: .utf8)
            if let peripheral = bluetoothManager.connectedPeripheral {
                peripheral.writeValue(startCommand!, for: txCharacteristic, type: .withoutResponse)
                print("✅ Sent START command to characteristic \(txCharacteristic.uuid)")
            }
        }

        measurementInProgress = true
        remainingTime = 15.0

        bluetoothManager.ekgData = []

        bluetoothManager.startMeasurement()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.remainingTime > 0 {
                self.remainingTime -= 1.0
            } else {
                stopMeasurement()
            }
        }
    }

    private func stopMeasurement() {
        if let txCharacteristic = bluetoothManager.txCharacteristic {
            let stopCommand = "STOP\n".data(using: .utf8)
            if let peripheral = bluetoothManager.connectedPeripheral {
                peripheral.writeValue(stopCommand!, for: txCharacteristic, type: .withoutResponse)
                print("✅ Sent STOP command to characteristic \(txCharacteristic.uuid)")
            }
        }

        measurementInProgress = false
        timer?.invalidate()
        timer = nil
        bluetoothManager.stopMeasurement()

        saveMeasurementData()

        self.goToSurvey = true // Navigate instead of showing an alert
    }

    private func saveMeasurementData() {
        // Prepare your data to be saved
        let measurementData: [(time: Double, weight: Double, heartRate: Double)] = [
            (time: Date().timeIntervalSince1970, weight: latestLoadCellValue, heartRate: 60.0)  // Example data
        ]

        // Save the data with a name and the actual data
        storage.saveMeasurementData(named: "measurement_\(Date().timeIntervalSince1970)", data: measurementData)
    }

    private func setupPlayer() {
        guard let url = Bundle.main.url(forResource: "ecg", withExtension: "mp4") else {
            print("Error: Video file not found.")
            return
        }

        player = AVQueuePlayer()
        let playerItem = AVPlayerItem(url: url)
        playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem)
        player?.play()
    }
}

struct ProgressRing: View {
    var progress: Double // from 0.0 to 1.0
    var totalTime: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                .opacity(0.3)
                .foregroundColor(.red)

            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .foregroundColor(.red)
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * totalTime))s")
                .font(.title)
                .bold()
                .foregroundColor(.red)
        }
        .frame(width: 120, height: 120)
    }
}

struct MeasurementSummaryView: View {
    var weight: Double
    @State private var goToSurvey = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Evaluation Complete")
                .font(.largeTitle)
                .bold()
                .padding(.top)

            Text(String(format: "Your weight was: %.2f kg", weight))
                .font(.title2)
                .padding()

            Button("Proceed to Survey") {
                goToSurvey = true
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("Summary")
        .navigationDestination(isPresented: $goToSurvey) {
            SurveyView()
        }
    }
}
