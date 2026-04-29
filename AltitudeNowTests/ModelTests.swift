import XCTest
@testable import AltitudeNow

final class ModelTests: XCTestCase {

    func testReadingCodableRoundTrip() throws {
        let r = AltitudeReading(timestamp: Date(timeIntervalSince1970: 1_700_000_000), relativeAltitude: 12.5, pressure: 101.32)
        let data = try JSONEncoder().encode(r)
        let decoded = try JSONDecoder().decode(AltitudeReading.self, from: data)
        XCTAssertEqual(decoded, r)
    }

    func testSessionUpdateMaintainsExtrema() {
        var s = Session(name: nil, startedAt: .now, readings: [])

        let readings = [
            AltitudeReading(timestamp: .now, relativeAltitude:   0.0, pressure: 101.0),
            AltitudeReading(timestamp: .now, relativeAltitude:  10.0, pressure: 100.5),
            AltitudeReading(timestamp: .now, relativeAltitude: -2.5,  pressure: 101.5),
            AltitudeReading(timestamp: .now, relativeAltitude:   7.5, pressure: 100.7),
        ]
        for r in readings {
            s.readings.append(r)
            s.update(with: r)
        }

        XCTAssertEqual(s.maxAltitude, 10.0, accuracy: 1e-6)
        XCTAssertEqual(s.minAltitude, -2.5, accuracy: 1e-6)
        XCTAssertEqual(s.altitudeGain, 12.5, accuracy: 1e-6)
        XCTAssertEqual(s.avgPressure, (101.0 + 100.5 + 101.5 + 100.7) / 4, accuracy: 1e-3)
    }

    func testAltitudeUnitFormatting() {
        XCTAssertEqual(AltitudeUnit.meters.formatted(100), "100.0 m")
        let ftValue = AltitudeUnit.feet.formatted(100)
        // 100 m = ~328.084 ft
        XCTAssertTrue(ftValue.contains("328"))
    }

    func testPressureUnitFormatting() {
        // 100 kPa = 1000 hPa
        XCTAssertEqual(PressureUnit.hPa.formatted(kPa: 100.0), "1000.00 hPa")
        // 100 kPa ≈ 29.5300 inHg
        let inHg = PressureUnit.inHg.formatted(kPa: 100.0)
        XCTAssertTrue(inHg.contains("29.53"))
    }

    func testCalibrationOffsetPersists() {
        let store = AltimeterStore()
        store.setCalibration(offsetMeters: 12.7)
        XCTAssertEqual(store.calibrationOffset, 12.7, accuracy: 1e-6)

        // Reload from disk into a new instance
        let reloaded = AltimeterStore()
        XCTAssertEqual(reloaded.calibrationOffset, 12.7, accuracy: 1e-6)

        // Reset state
        reloaded.setCalibration(offsetMeters: 0)
    }

    func testSensorFlagIsBoolean() {
        // We can't assert true/false (depends on host), but we can assert the property exists & is a Bool.
        let v: Bool = AltimeterStore.isSensorAvailable
        XCTAssertNotNil(v)
    }
}
