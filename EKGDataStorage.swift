//
//  EKGDataStorage.swift
//  Heart Sentry
//
//  Created by Hayden Carlson on 3/22/25.
//

import Foundation

class EKGDataStorage {
    public let fileManager: FileManager
    public lazy var directory: URL = {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    init() {
        self.fileManager = FileManager.default
    }

    // Save raw data to a file (in a flat array format)
    func saveRawData(named name: String, data: [[Double]]) {
        let fileURL = directory.appendingPathComponent("\(name).txt")

        do {
            let header = "Time,LoadCell1,LoadCell2,LoadCell3,LoadCell4,EKG Lead 1,EKG Lead 2\n"
            let dataString = data.enumerated().map { (index, values) -> String in
                let time = Double(index) * 1.0  // Assuming index represents time, adjust as necessary
                let valuesString = values.map { String($0) }.joined(separator: ",")
                return "\(time),\(valuesString)"
            }.joined(separator: "\n")

            try (header + dataString).write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving raw data: \(error)")
        }
    }

    // Load data from a file into EKGDataPoint objects
    func loadData(named name: String) -> [EKGDataPoint]? {
        let fileURL = directory.appendingPathComponent("\(name).txt")

        do {
            let dataString = try String(contentsOf: fileURL, encoding: .utf8)
            print("File contents preview:\n\(dataString.prefix(500))")  // Show first 500 characters

            let lines = dataString.split(separator: "\n").dropFirst() // Skip header line

            let dataPoints = lines.compactMap { line -> EKGDataPoint? in
                let parts = line.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

                if parts.count != 7 {
                    print("Skipping line (wrong column count): \(line)")
                    return nil
                }

                guard let time = TimeInterval(parts[0]) else {
                    print("Skipping line (invalid time): \(line)")
                    return nil
                }

                let values = parts[1...6].compactMap { Double($0) }
                if values.count != 6 {
                    print("Skipping line (bad numeric values): \(line)")
                    return nil
                }

                return EKGDataPoint(time: time, values: values)
            }

            print("Parsed \(dataPoints.count) data points successfully.")
            return dataPoints
        } catch {
            print("Error loading data: \(error)")
            return nil
        }
    }


    // Load all measurement names (file names without extension)
    func loadAllMeasurementNames() -> [String] {
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let fileNames = files.filter { $0.pathExtension == "txt" }
                .map { $0.deletingPathExtension().lastPathComponent }
            return fileNames
        } catch {
            print("Error loading file names: \(error)")
            return []
        }
    }

    // Delete all stored data
    func deleteAllData() {
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "txt" {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Error deleting all data: \(error)")
        }
    }
    
    
}
