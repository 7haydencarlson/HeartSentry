//
//  BluetoothManager.swift
//  Heart Sentry
//
//  Created by Hayden Carlson on 3/21/25.
//
import CoreBluetooth
import SwiftUI

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var ekgData: [EKGDataPoint] = []
    @Published var connectionStatus: String = "Scanning for Bluetooth devices..."
    @Published var selectedPeripheral: CBPeripheral?
    @Published var connectedPeripheral: CBPeripheral?
    @Published var isMeasuring: Bool = false
    @State var showDisconnectionPopup: Bool = false
    
    static let shared = BluetoothManager() // Ensure a persistent reference
    
    var centralManager: CBCentralManager!
    var rxCharacteristic: CBCharacteristic?
    var txCharacteristic: CBCharacteristic?
    var connectionError: String = "No Error"
    private var startTime = Date()
    
    required override init() {
        super.init()
        centralManager = CBCentralManager(
                delegate: self,
                queue: nil,
                options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            if central.state == .poweredOn {
                self.connectionStatus = "Scanning for devices..."
                self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            } else {
                self.connectionStatus = "Bluetooth is not available"
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let deviceName = peripheral.name, !deviceName.isEmpty else { return }
        
        DispatchQueue.main.async {
            if !self.discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                self.discoveredDevices.append(peripheral)
            }
        }
    }
    
    func connectToDevice(_ peripheral: CBPeripheral) {
        self.selectedPeripheral = peripheral
        self.connectionStatus = "Connecting to \(peripheral.name ?? "Device")..."
        self.centralManager.stopScan()
        self.centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.connectionStatus = "Connected to \(peripheral.name ?? "Unknown")"
        }
        print("Connected to \(peripheral.name ?? "Unknown")")
        self.connectedPeripheral = peripheral  // Ensure it's retained
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Update the connection status to reflect the disconnection
        DispatchQueue.main.async {
            if let error = error {
                self.connectionStatus = "Disconnected"
                self.connectionError = "Disconnected from \(peripheral.name ?? "Unknown") due to error: \(error.localizedDescription)"
                self.showDisconnectionAlert(message: self.connectionError)
            } else {
                self.connectionStatus = "Disconnected from \(peripheral.name ?? "Unknown")"
                self.showDisconnectionAlert(message: self.connectionError)
            }
        }
        
        // Set the connectedPeripheral to nil since the peripheral is no longer connected
        self.connectedPeripheral = nil
        print("Disconnected from \(peripheral.name ?? "Unknown")")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.read) {
                        self.rxCharacteristic = characteristic
                        peripheral.setNotifyValue(true, for: characteristic)
                        peripheral.readValue(for: characteristic)
                    }
                    
            // Handle the characteristic for writing data (sending commands)
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                self.txCharacteristic = characteristic
                print("Write characteristic discovered: \(characteristic.uuid)")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.connectionStatus = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error receiving data: \(error.localizedDescription)")
            return
        }
        
        guard characteristic.value != nil else {
            print("No data received")
            return
        }

        // Interpret as a little-endian IEEE float (common format for sensor data)
        DispatchQueue.main.async {
            let timeElapsed = Date().timeIntervalSince(self.startTime)
            
            guard let data = characteristic.value else {
                print("No data received")
                return
            }

            // Example: Assume data contains two floats (ECG value and Load Cell value)
            if data.count >= 2 * MemoryLayout<Float>.size {
                // Parse the ECG value (first float)
                let ecgValue = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: Float.self) }

                // Parse the Load Cell value (second float)
                let loadCellValue = data.withUnsafeBytes { $0.load(fromByteOffset: MemoryLayout<Float>.size, as: Float.self) }

                // Append both values to the ekgData array
                if self.isMeasuring {
                    self.ekgData.append(EKGDataPoint(time: timeElapsed, values: [Double(ecgValue), Double(loadCellValue)]))
                }
            } else {
                print("Received data too short to interpret as two Floats: \(data.count) bytes")
            }
        }

    }

    func startMeasurement() {
            DispatchQueue.main.async {
                self.isMeasuring = true
                self.ekgData.removeAll()  // Clear old data
                print("Measurement started!")
            }
        }

    func stopMeasurement() {
        DispatchQueue.main.async {
            self.isMeasuring = false
            print("Measurement ended.")
        }
    }
    private func showDisconnectionAlert(message: String) {
        // Create an alert controller
        let alert = UIAlertController(title: "Disconnected", message: message, preferredStyle: .alert)
        
        // Add a button to dismiss the alert
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // Present the alert for the correct window in case of multiple scenes
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                rootViewController.present(alert, animated: true, completion: nil)
            }
        }
    }

}
