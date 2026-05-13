import Foundation
import CoreMotion
import Observation
import UIKit

@Observable
final class AltimeterStore {
    /// Whether a barometric pressure sensor is reachable. Real devices: depends on hardware
    /// (iPhone 6+ all have one). Simulator: always false. In `-FASTLANE_SNAPSHOT` mode
    /// (UI tests / store screenshots) we override this to `true` so the screenshot path
    /// renders the readouts and chart instead of the "no sensor" content view.
    static var isSensorAvailable: Bool {
        if ProcessInfo.processInfo.arguments.contains("-FASTLANE_SNAPSHOT") { return true }
        return CMAltimeter.isRelativeAltitudeAvailable()
    }

    static let sessionsCap = 200

    // Live state
    var current: AltitudeReading?
    var liveSession: Session?
    var isRunning: Bool = false

    /// Tracks the session's peak altitude so we can fire haptic feedback when
    /// the user surpasses their previous high-point by at least 1 m.
    private var sessionPeak: Double = -Double.infinity
    // TODO(v1.1): play peak ding.aiff when surpassing sessionPeak

    // Persisted state
    var sessions: [Session] = []
    var calibrationOffset: Double = 0
    var altitudeUnit: AltitudeUnit = .meters
    var pressureUnit: PressureUnit = .hPa

    private let altimeter = CMAltimeter()

    init() {
        load()
        if ProcessInfo.processInfo.arguments.contains("-FASTLANE_SNAPSHOT") {
            injectSnapshotData()
        }
    }

    private func injectSnapshotData() {
        // Build a 60-minute mock session with smooth altitude/pressure curves so the
        // chart card has shape. Used only for App Store screenshots; never reached in prod.
        let now = Date()
        var session = Session(name: "Mountain hike", startedAt: now.addingTimeInterval(-3600), readings: [])
        for i in 0..<60 {
            let t = now.addingTimeInterval(TimeInterval(-3600 + i * 60))
            let alt = sin(Double(i) * 0.12) * 25 + Double(i) * 0.6
            let pr = 101.0 - Double(i) * 0.018
            let r = AltitudeReading(timestamp: t, relativeAltitude: alt, pressure: pr)
            session.readings.append(r)
            session.update(with: r)
        }
        liveSession = session
        current = session.readings.last
        isRunning = true

        // Add a finished prior session so the SessionList screenshot has content.
        var prior = Session(name: "Trail run", startedAt: now.addingTimeInterval(-86_400 - 1800), readings: [])
        for i in 0..<30 {
            let t = prior.startedAt.addingTimeInterval(TimeInterval(i * 60))
            let alt = cos(Double(i) * 0.2) * 18 + Double(i) * 0.4
            let pr = 100.5 - Double(i) * 0.02
            let r = AltitudeReading(timestamp: t, relativeAltitude: alt, pressure: pr)
            prior.readings.append(r)
            prior.update(with: r)
        }
        prior.endedAt = prior.startedAt.addingTimeInterval(1800)
        sessions = [prior]
    }

    deinit {
        if isRunning { altimeter.stopRelativeAltitudeUpdates() }
    }

    func start(name: String? = nil) {
        guard Self.isSensorAvailable, !isRunning else { return }
        isRunning = true
        sessionPeak = -Double.infinity
        liveSession = Session(name: name, startedAt: .now, readings: [])
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let self, let data else { return }
            let newAltitude = data.relativeAltitude.doubleValue + self.calibrationOffset
            let reading = AltitudeReading(
                timestamp: .now,
                relativeAltitude: newAltitude,
                pressure: data.pressure.doubleValue
            )
            self.current = reading
            self.liveSession?.readings.append(reading)
            self.liveSession?.update(with: reading)
            // Peak haptic: fire when user surpasses previous session high by +1 m.
            if newAltitude > self.sessionPeak + 1.0 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.sessionPeak = newAltitude
            }
        }
    }

    func stop() {
        _ = stopAndReturnSavedSession()
    }

    /// Stop the live session and return the persisted `Session` (with `endedAt`
    /// set) if anything was actually saved. Returns `nil` if the live session
    /// was empty or if no session was running. Used by the Stop button to
    /// chain follow-up writes (e.g. Apple Health) without re-querying state.
    @discardableResult
    func stopAndReturnSavedSession() -> Session? {
        guard isRunning else { return nil }
        altimeter.stopRelativeAltitudeUpdates()
        isRunning = false
        sessionPeak = -Double.infinity
        var savedSession: Session?
        if var s = liveSession, !s.readings.isEmpty {
            s.endedAt = .now
            sessions.insert(s, at: 0)
            if sessions.count > Self.sessionsCap {
                sessions = Array(sessions.prefix(Self.sessionsCap))
            }
            save()
            savedSession = s
        }
        liveSession = nil
        current = nil
        if savedSession != nil {
            Task { @MainActor in
                ReviewService.recordSuccess()
                ReviewService.maybeRequestReview()
            }
        }
        return savedSession
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
