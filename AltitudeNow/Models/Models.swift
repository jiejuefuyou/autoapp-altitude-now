import Foundation

struct AltitudeReading: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let timestamp: Date
    /// Meters above (or below, if negative) the session's start point.
    let relativeAltitude: Double
    /// Atmospheric pressure in kilopascals (kPa).
    let pressure: Double

    init(id: UUID = UUID(), timestamp: Date, relativeAltitude: Double, pressure: Double) {
        self.id = id
        self.timestamp = timestamp
        self.relativeAltitude = relativeAltitude
        self.pressure = pressure
    }

    enum CodingKeys: String, CodingKey {
        case id, timestamp, relativeAltitude, pressure
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id               = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.timestamp        = try c.decode(Date.self, forKey: .timestamp)
        self.relativeAltitude = try c.decode(Double.self, forKey: .relativeAltitude)
        self.pressure         = try c.decode(Double.self, forKey: .pressure)
    }
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

    init(id: UUID = UUID(),
         name: String? = nil,
         startedAt: Date,
         endedAt: Date? = nil,
         readings: [AltitudeReading] = [],
         maxAltitude: Double = 0,
         minAltitude: Double = 0,
         avgPressure: Double = 0) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.readings = readings
        self.maxAltitude = maxAltitude
        self.minAltitude = minAltitude
        self.avgPressure = avgPressure
    }

    enum CodingKeys: String, CodingKey {
        case id, name, startedAt, endedAt, readings, maxAltitude, minAltitude, avgPressure
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id           = try c.decodeIfPresent(UUID.self,              forKey: .id) ?? UUID()
        self.name         = try c.decodeIfPresent(String.self,            forKey: .name)
        self.startedAt    = try c.decode(Date.self,                       forKey: .startedAt)
        self.endedAt      = try c.decodeIfPresent(Date.self,              forKey: .endedAt)
        self.readings     = try c.decodeIfPresent([AltitudeReading].self, forKey: .readings) ?? []
        self.maxAltitude  = try c.decodeIfPresent(Double.self,            forKey: .maxAltitude) ?? 0
        self.minAltitude  = try c.decodeIfPresent(Double.self,            forKey: .minAltitude) ?? 0
        self.avgPressure  = try c.decodeIfPresent(Double.self,            forKey: .avgPressure) ?? 0
    }

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
