//
//  ContentView.swift
//  Heart Sentry
//
//  Created by Hayden Carlson on 3/20/25.
//

import SwiftUI

struct BluetoothView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var body: some View {
        NavigationView {
            VStack {
                Text(bluetoothManager.connectionStatus)
                    .font(.headline)
                    .padding()

                List(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                    Button(device.name ?? "Unknown") {
                        bluetoothManager.connectToDevice(device)
                    }
                }
            }
            .navigationTitle("Bluetooth Settings")
        }
    }
}
