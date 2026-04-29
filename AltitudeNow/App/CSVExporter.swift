import Foundation

enum CSVExporter {
    /// Builds a CSV string with header `timestamp,relative_altitude_m,pressure_kpa`.
    static func csv(for session: Session) -> String {
        var lines: [String] = ["timestamp,relative_altitude_m,pressure_kpa"]
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for r in session.readings {
            let ts = isoFormatter.string(from: r.timestamp)
            let alt = String(format: "%.4f", r.relativeAltitude)
            let pr  = String(format: "%.4f", r.pressure)
            lines.append("\(ts),\(alt),\(pr)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Writes the CSV to a temp file and returns its URL, suitable for ShareLink.
    static func writeTempCSV(for session: Session) throws -> URL {
        let tmp = FileManager.default.temporaryDirectory
        let safeName = session.displayTitle
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        let filename = "altitudenow-\(safeName.isEmpty ? UUID().uuidString.prefix(8) : safeName).csv"
        let url = tmp.appendingPathComponent(String(filename))
        try csv(for: session).data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
}
