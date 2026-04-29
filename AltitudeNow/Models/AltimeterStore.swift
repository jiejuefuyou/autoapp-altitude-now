import Foundation
import CoreMotion
import Observation

@Observable
final class AltimeterStore {
    static let isSensorAvailable: Bool = CMAltimeter.isRelativeAltitudeAvailable()
    static let sessionsCap = 200

    // Live state
    var current: AltitudeReading?
    var liveSession: Session?
    var isRunning: Bool = false

    // Persisted state
    var sessions: [Session] = []
    var calibrationOffset: Double = 0
    var altitudeUnit: AltitudeUnit = .meters
    var pressureUnit: PressureUnit = .hPa

    private let altimeter = CMAltimeter()

    init() {
        load()
    }

    deinit {
        if isRunning { altimeter.stopRelativeAltitudeUpdates() }
    }

    func start(name: String? = nil) {
        guard Self.isSensorAvailable, !isRunning else { return }
        isRunning = true
        liveSession = Session(name: name, startedAt: .now, readings: [])
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self, let data else { return }
            let reading = AltitudeReading(
                timestamp: .now,
                relativeAltitude: data.relativeAltitude.doubleValue + self.calibrationOffset,
                pressure: data.pressure.doubleValue
            )
            self.current = reading
            self.liveSession?.readings.append(reading)
            self.liveSession?.update(with: reading)
        }
    }

    func stop() {
        guard isRunning else { return }
        altimeter.stopRelativeAltitudeUpdates()
        isRunning = false
        if var s = liveSession, !s.readings.isEmpty {
            s.endedAt = .now
            sessions.insert(s, at: 0)
            if sessions.count > Self.sessionsCap {
                sessions = Array(sessions.prefix(Self.sessionsCap))
            }
            save()
        }
        liveSession = nil
        current = nil
    }

    func reset() {
        let wasRunning = isRunning
        if wasRunning { stop() }
        if wasRunning { start() }
    }

    func deleteSession(_ s: Session) {
        sessions.removeAll { $0.id == s.id }
        save()
    }

    func clearSessions() {
        sessions.removeAll()
        save()
    }

    func setCalibration(offsetMeters: Double) {
        calibrationOffset = offsetMeters
        save()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var sessions: [Session]
        var calibrationOffset: Double
        var altitudeUnit: AltitudeUnit
        var pressureUnit: PressureUnit
    }

    private var saveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("altitudenow_state.json")
    }

    private func save() {
        let snap = Snapshot(
            sessions: sessions,
            calibrationOffset: calibrationOffset,
            altitudeUnit: altitudeUnit,
            pressureUnit: pressureUnit
        )
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: saveURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        sessions = snap.sessions
        calibrationOffset = snap.calibrationOffset
        altitudeUnit = snap.altitudeUnit
        pressureUnit = snap.pressureUnit
    }
}
