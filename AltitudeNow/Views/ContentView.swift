import SwiftUI
import Charts

struct ContentView: View {
    @Environment(AltimeterStore.self) private var store
    @Environment(IAPManager.self) private var iap

    @State private var showSessions = false
    @State private var showSettings = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if AltimeterStore.isSensorAvailable {
                    readouts
                    chartCard
                    Spacer(minLength: 0)
                    controls
                } else {
                    unsupportedDevice
                }
            }
            .padding()
            .navigationTitle("AltitudeNow")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSessions = true } label: { Image(systemName: "list.bullet.clipboard") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gear") }
                }
            }
            .sheet(isPresented: $showSessions) { SessionListView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var readouts: some View {
        HStack(spacing: 16) {
            readoutCard(title: "Altitude",
                        value: store.altitudeUnit.formatted(store.current?.relativeAltitude ?? 0),
                        icon: "mountain.2")
            readoutCard(title: "Pressure",
                        value: store.pressureUnit.formatted(kPa: store.current?.pressure ?? 0),
                        icon: "barometer")
        }
    }

    private func readoutCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.title2, design: .rounded, weight: .semibold)).contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var chartCard: some View {
        let readings = store.liveSession?.readings ?? []
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Live altitude", systemImage: "waveform.path.ecg").font(.caption).foregroundStyle(.secondary)
                Spacer()
                if let s = store.liveSession {
                    Text(s.startedAt, style: .timer).font(.caption.monospacedDigit())
                }
            }
            if readings.isEmpty {
                ContentUnavailableView("Press Start to record", systemImage: "play.circle")
                    .frame(height: 180)
            } else {
                Chart {
                    ForEach(readings) { r in
                        LineMark(x: .value("t", r.timestamp), y: .value("alt", r.relativeAltitude))
                            .interpolationMethod(.monotone)
                    }
                }
                .chartYAxisLabel("m")
                .frame(height: 180)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private var controls: some View {
        HStack(spacing: 12) {
            if !store.isRunning {
                Button {
                    if store.sessions.count >= 1, !iap.isPremium {
                        // Free tier: only the most recent session is retained — non-premium users
                        // can still record, but old sessions are auto-purged.
                    }
                    store.start()
                } label: {
                    Label("Start", systemImage: "play.fill").frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button { store.stop() } label: {
                    Label("Stop", systemImage: "stop.fill").frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent).tint(.red)

                Button { store.reset() } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var unsupportedDevice: some View {
        ContentUnavailableView {
            Label("No barometric sensor", systemImage: "exclamationmark.triangle")
        } description: {
            Text("AltitudeNow needs a device with a barometric pressure sensor. iPhone 6 and newer all have one. The iOS Simulator does not.")
        }
    }
}

#Preview {
    ContentView()
        .environment(AltimeterStore())
        .environment(IAPManager())
}
