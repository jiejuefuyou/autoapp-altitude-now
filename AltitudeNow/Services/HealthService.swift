import Foundation
import HealthKit

/// Writes AltitudeNow session data to Apple Health as workout samples
/// with elevation-ascended and route-distance metadata. Read-only intent
/// for the user: we never read existing health data, only contribute samples.
@MainActor
final class HealthService {
    static let shared = HealthService()

    private let store = HKHealthStore()

    /// Whether HealthKit is supported on this device. iPad without health data → false.
    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// The set of types we write — workout + elevation ascended quantity.
    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let elevation = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(elevation)
        }
        return types
    }

    /// Request Apple Health write authorization. The system shows the standard
    /// permission sheet. Returns `true` on user grant or already-authorized; `false`
    /// otherwise (denied or unsupported device).
    func requestAuthorization() async -> Bool {
        guard Self.isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: writeTypes, read: [])
            return true
        } catch {
            return false
        }
    }

    /// Whether the user has authorized writing workout samples. Apple Health
    /// intentionally hides denied state, so this returns `true` only when
    /// status is `.sharingAuthorized`.
    var isAuthorizedToWrite: Bool {
        guard Self.isAvailable else { return false }
        return store.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    /// Save a finished session as a generic `.other` workout. The session's
    /// elevation gain (max - min) becomes the `HKMetadataKeyElevationAscended`
    /// metadata in meters. Returns `true` on success.
    @discardableResult
    func saveSessionAsWorkout(_ session: Session) async -> Bool {
        guard Self.isAvailable, isAuthorizedToWrite else { return false }
        guard !session.readings.isEmpty else { return false }

        let start = session.startedAt
        let end = session.endedAt ?? session.readings.last?.timestamp ?? start
        guard end > start else { return false }

        let gain = HKQuantity(unit: .meter(), doubleValue: max(0, session.altitudeGain))
        let metadata: [String: Any] = [
            HKMetadataKeyElevationAscended: gain,
            HKMetadataKeyWorkoutBrandName: "AltitudeNow"
        ]

        let workout = HKWorkout(
            activityType: .other,
            start: start,
            end: end,
            duration: end.timeIntervalSince(start),
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: metadata
        )

        return await withCheckedContinuation { continuation in
            store.save(workout) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
