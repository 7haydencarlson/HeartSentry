//
//  HomePageView.swift
//  Heart Sentry
//
//  Created by Hayden Carlson on 3/20/25.
//
import SwiftUI

struct HomePageView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager  // Access BluetoothManager

    var body: some View {
        NavigationView {
            VStack {
                Text("Heart Sentry")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                NavigationLink(destination: MeasurementView()) {
                    Text("Start New Measurement")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                NavigationLink(destination: PreviousMeasurementsView()) {
                    Text("View Previous Measurements")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                NavigationLink(destination: CalibrationView()) {
                    Text("Calibrate Load Cells")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                
            }
            //.navigationTitle("Home")
            .navigationBarItems(trailing: NavigationLink(destination: ProfileView()) {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            })
            
            .navigationBarItems(trailing: NavigationLink(destination: BluetoothView()) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title)
                    .foregroundColor(.blue)
            })
        }
    }
}


