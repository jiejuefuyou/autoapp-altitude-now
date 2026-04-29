import Foundation

struct AltitudeReading: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let timestamp: Date
    /// Meters above (or below, if negative) the session's start point.
    let relativeAltitude: Double
    /// Atmospheric pressure in kilopascals (kPa).
    let pressure: Double
}

struct Session: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String?
    let startedAt: Date
    var endedAt: Date?
    var readings: [AltitudeReading]

    var maxAltitude: Double = 0
    var minAltitude: Double = 0
    var avgPressure: Double = 0

    var duration: TimeInterval {
        (endedAt ?? .now).timeIntervalSince(startedAt)
    }

    var altitudeGain: Double { maxAltitude - minAltitude }

    var displayTitle: String {
        if let name, !name.isEmpty { return name }
        return startedAt.formatted(date: .abbreviated, time: .shortened)
    }

    mutating func update(with r: AltitudeReading) {
        if readings.count == 1 {
            maxAltitude = r.relativeAltitude
            minAltitude = r.relativeAltitude
            avgPressure = r.pressure
        } else {
            maxAltitude = max(maxAltitude, r.relativeAltitude)
            minAltitude = min(minAltitude, r.relativeAltitude)
            // running mean
            let n = Double(readings.count)
            avgPressure = avgPressure + (r.pressure - avgPressure) / n
        }
    }
}

enum AltitudeUnit: String, Codable, CaseIterable, Identifiable {
    case meters = "m"
    case feet = "ft"
    var id: String { rawValue }

    func formatted(_ meters: Double) -> String {
        switch self {
        case .meters: return String(format: "%.1f m", meters)
        case .feet:   return String(format: "%.1f ft", meters * 3.28084)
        }
    }
}

enum PressureUnit: String, Codable, CaseIterable, Identifiable {
    case hPa
    case inHg
    var id: String { rawValue }

    /// `kPa` is the unit `CMAltimeter` reports.
    func formatted(kPa: Double) -> String {
        switch self {
        case .hPa:  return String(format: "%.2f hPa", kPa * 10)
        case .inHg: return String(format: "%.2f inHg", kPa * 0.295299830714)
        }
    }
}
