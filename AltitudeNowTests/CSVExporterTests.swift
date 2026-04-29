import XCTest
@testable import AltitudeNow

final class CSVExporterTests: XCTestCase {

    func testCSVHeader() {
        let session = Session(name: "test", startedAt: Date(timeIntervalSince1970: 0), readings: [])
        let csv = CSVExporter.csv(for: session)
        XCTAssertTrue(csv.hasPrefix("timestamp,relative_altitude_m,pressure_kpa\n"))
    }

    func testCSVRowsForReadings() {
        let r1 = AltitudeReading(timestamp: Date(timeIntervalSince1970: 100), relativeAltitude: 1.5, pressure: 101.3)
        let r2 = AltitudeReading(timestamp: Date(timeIntervalSince1970: 101), relativeAltitude: 2.0, pressure: 101.2)
        let session = Session(name: "t", startedAt: Date(timeIntervalSince1970: 0), readings: [r1, r2])
        let csv = CSVExporter.csv(for: session)
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(String(lines[1]).contains("1.5000"))
        XCTAssertTrue(String(lines[2]).contains("2.0000"))
    }
}
