import SwiftUI
import Charts

struct ContentView: View {
    @Environment(AltimeterStore.self) private var store
    @Environment(IAPManager.self) private var iap

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    @State private var showSessions = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showMountainList = false
    @State private var pendingSessionName: String = ""

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
            .sheet(isPresented: $showMountainList) {
                MountainListView { name, _ in
                    pendingSessionName = name
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { !hasSeenOnboarding },
                set: { _ in /* OnboardingView writes hasSeenOnboarding directly */ }
            )) {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
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
        VStack(spacing: 10) {
            if !store.isRunning {
                // Session name field — pre-filled from 100名山 picker or typed manually
                HStack(spacing: 8) {
                    TextField("Session name (optional)", text: $pendingSessionName)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        showMountainList = true
                    } label: {
                        Label(
                            String(localized: "japan_mountains_choose_button"),
                            systemImage: "mountain.2"
                        )
                        .labelStyle(.iconOnly)
                        .padding(8)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(String(localized: "japan_mountains_choose_button"))
                }
            }
            HStack(spacing: 12) {
            if !store.isRunning {
                Button {
                    Haptics.medium()
                    let name = pendingSessionName.trimmingCharacters(in: .whitespaces)
                    store.start(name: name.isEmpty ? nil : name)
                    pendingSessionName = ""
                } label: {
                    Label("Start", systemImage: "play.fill").frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    Haptics.medium()
                    store.stop()
                    Haptics.success()
                } label: {
                    Label("Stop", systemImage: "stop.fill").frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent).tint(.red)

                Button {
                    Haptics.light()
                    store.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.bordered)
            }
            } // end HStack(spacing: 12)
        } // end VStack
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
