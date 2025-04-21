//
//  Heart_SentryApp.swift
//  Heart Sentry
//
//  Created by Hayden Carlson on 3/20/25.
//

import CoreBluetooth
import SwiftUI

@main
struct Heart_SentryApp: App {
    @StateObject private var bluetoothManager = BluetoothManager()  // Create the BluetoothManager instance

    var body: some Scene {
        WindowGroup {
            HomePageView()
                .environmentObject(bluetoothManager)  // Inject the BluetoothManager into the environment
        }
    }
}


