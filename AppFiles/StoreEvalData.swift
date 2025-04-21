//
//  StoreEvalData.swift
//  Heart Sentry
//
//  Created by Hayden Carlson on 4/20/25.
//


import Foundation

// StoreEvalData.swift
class StoreEvalData {
    // Define the directory or storage location
    var directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    // Add the saveMeasurementData method
    func saveMeasurementData(named name: String, data: [(time: Double, weight: Double, heartRate: Double)]) {
        let fileURL = directory.appendingPathComponent("\(name).txt")
        
        // Convert the data into a string format
        var dataString = ""
        for entry in data {
            dataString.append("\(entry.time),\(entry.weight),\(entry.heartRate)\n")
        }
        
        do {
            try dataString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Successfully saved data to \(fileURL.path)")
        } catch {
            print("Error saving data: \(error)")
        }
    }
    // Method to load all measurement names
    func loadAllMeasurementNames() -> [String] {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: directory.path)
            return files.filter { $0.hasSuffix(".txt") } // Assuming text files are your measurement files
        } catch {
            print("Error loading measurement names: \(error)")
            return []
        }
    }

    // Method to load measurement data by name
    // Method to load measurement data by name
    func loadMeasurementData(named name: String) -> [(time: Double, weight: Double, heartRate: Double)]? {
        // Check if the name already ends with .txt and avoid appending again
        let fileName = name.hasSuffix(".txt") ? name : "\(name).txt"
        let fileURL = directory.appendingPathComponent(fileName)
        
        do {
            let data = try String(contentsOf: fileURL, encoding: .utf8)
            // Assuming the data is CSV formatted or has a similar structure
            let lines = data.split(separator: "\n")
            var measurementData: [(Double, Double, Double)] = []
            for line in lines {
                let components = line.split(separator: ",")
                if components.count >= 3,
                   let time = Double(components[0]),
                   let weight = Double(components[1]),
                   let heartRate = Double(components[2]) {
                    measurementData.append((time, weight, heartRate))
                }
            }
            return measurementData
        } catch {
            print("Error loading data for measurement \(name): \(error)")
            return nil
        }
    }


    // Method to delete all stored data
    func deleteAllData() {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: directory.path)
            for file in files {
                let filePath = directory.appendingPathComponent(file)
                try fileManager.removeItem(at: filePath)
            }
        } catch {
            print("Error deleting data: \(error)")
        }
    }
}
