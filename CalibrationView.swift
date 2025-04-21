import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var calibrationStatus: String = "Waiting to start calibration..."
    @State private var isCalibrating: Bool = false
    @State private var knownWeight: String = ""  // New state for weight input

    var body: some View {
        VStack(spacing: 20) {
            Text("Load Cell Calibration")
                .font(.title)
                .fontWeight(.bold)
            
            Text(calibrationStatus)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {
                startCalibration()
            }) {
                Text("Start Calibration")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isCalibrating ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(isCalibrating || bluetoothManager.txCharacteristic == nil)
            
            // Input field for known weight
            if isCalibrating {
                TextField("Enter known weight (g)", text: $knownWeight)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Button(action: {
                // Check if the input can be converted to a Float
                if let weight = Float(knownWeight) {
                    sendCommand("CAL:\(weight)")
                    print("Sent CAL:\(weight)")
                    isCalibrating = false
                    calibrationStatus = "Calibration complete. You can now begin measurement."
                } else {
                    print("Invalid weight input: \(knownWeight)")
                    calibrationStatus = "Please enter a valid number for the weight."
                }
            }) {
                Text("Finish Calibration")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isCalibrating ? Color.green : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!isCalibrating || bluetoothManager.txCharacteristic == nil)
        }
        .padding()
    }
    
    func startCalibration() {
        sendCommand("TARE")
        isCalibrating = true
        calibrationStatus = "Tare sent. Place known weight on scale and press Finish Calibration when ready."
    }
    
    func sendCommand(_ command: String) {
        guard let txCharacteristic = bluetoothManager.txCharacteristic,
              let peripheral = bluetoothManager.connectedPeripheral else {
            print("No connected peripheral or writable characteristic found.")
            return
        }
        if let utfcommand = command.data(using: .utf8) {
            peripheral.writeValue(utfcommand, for: txCharacteristic, type: .withoutResponse)
            print("Command '\(command)' sent to device.")
        }
    }
}
