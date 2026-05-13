import SwiftUI
import Charts

/// Premium-only detail view for a single session. Shows a large interactive
/// SwiftUI Chart of altitude vs. time plus summary stats. Free users see a
/// paywall placeholder instead of the chart.
struct SessionDetailView: View {
    let session: Session

    @Environment(AltimeterStore.self) private var store
    @Environment(IAPManager.self) private var iap

    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statsCard
                if iap.isPremium {
                    chartCard
                } else {
                    lockedChartCard
                }
                metadataCard
            }
            .padding()
        }
        .navigationTitle(Text(session.displayTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if iap.isPremium, let csvURL = try? CSVExporter.writeTempCSV(for: session) {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: csvURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(Text("Export CSV"))
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(LocalizedStringKey("Summary"), systemImage: "chart.bar")
                .font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 14) {
                statTile(LocalizedStringKey("max"),  store.altitudeUnit.formatted(session.maxAltitude),  a11yLabel: LocalizedStringKey("Maximum altitude"))
                statTile(LocalizedStringKey("min"),  store.altitudeUnit.formatted(session.minAltitude),  a11yLabel: LocalizedStringKey("Minimum altitude"))
                statTile(LocalizedStringKey("gain"), store.altitudeUnit.formatted(session.altitudeGain), a11yLabel: LocalizedStringKey("Altitude gain"))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func statTile(_ key: LocalizedStringKey, _ value: String, a11yLabel: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(key).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.callout.monospacedDigit().weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(a11yLabel)
        .accessibilityValue(Text(value))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Altitude over time"), systemImage: "chart.xyaxis.line")
                .font(.caption).foregroundStyle(.secondary)
            if session.readings.count < 2 {
                ContentUnavailableView(
                    LocalizedStringKey("Not enough data"),
                    systemImage: "waveform.path.ecg",
                    description: Text(LocalizedStringKey("This session has too few readings to plot."))
                )
                .frame(height: 220)
            } else {
                Chart {
                    ForEach(session.readings) { r in
                        LineMark(
                            x: .value("t", r.timestamp),
                            y: .value("alt", r.relativeAltitude)
                        )
                        .interpolationMethod(.monotone)
                    }
                }
                .chartYAxisLabel("m")
                .frame(height: 260)
                .accessibilityLabel(Text(LocalizedStringKey("Session altitude chart")))
                .accessibilityHint(Text(LocalizedStringKey("Line chart showing altitude in meters over the session duration")))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var lockedChartCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(LocalizedStringKey("Detailed altitude charts"))
                .font(.headline)
            Text(LocalizedStringKey("Unlock Premium to see the full chart for every session."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(LocalizedStringKey("Unlock with Premium")) { showPaywall = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(LocalizedStringKey("Details"), systemImage: "info.circle")
                .font(.caption).foregroundStyle(.secondary)
            metadataRow(LocalizedStringKey("Started"), session.startedAt.formatted(date: .abbreviated, time: .standard))
            if let endedAt = session.endedAt {
                metadataRow(LocalizedStringKey("Ended"), endedAt.formatted(date: .abbreviated, time: .standard))
            }
            metadataRow(LocalizedStringKey("Duration"), durationString(session.duration))
            metadataRow(LocalizedStringKey("Readings"), "\(session.readings.count)")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func metadataRow(_ key: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(key).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.monospacedDigit())
        }
    }

    private func durationString(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
