import SwiftUI
import Charts

struct ContentView: View {
    @Environment(AltimeterStore.self) private var store
    @Environment(IAPManager.self) private var iap

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage(FavoriteMountains.storageKey) private var favoritedRaw: String = ""

    @State private var showSessions = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showMountainList = false
    @State private var pendingSessionName: String = ""

    private var quickSwitchMountains: [Mountain] {
        let ids = FavoriteMountains.decode(favoritedRaw).prefix(FavoriteMountains.maxQuickSwitch)
        return ids.compactMap { MountainData.mountain(for: $0) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if AltimeterStore.isSensorAvailable {
                    if !quickSwitchMountains.isEmpty && !store.isRunning {
                        quickSwitchBar
                    }
                    readouts
                    chartCard
                    Spacer(minLength: 0)
                    controls
                } else {
                    unsupportedDevice
                }
            }
            .padding()
            .navigationTitle(Text("AltitudeNow"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSessions = true } label: { Image(systemName: "list.bullet.clipboard") }
                        .accessibilityLabel(Text(LocalizedStringKey("Sessions")))
                        .accessibilityHint(Text(LocalizedStringKey("View all recorded altitude sessions")))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gear") }
                        .accessibilityLabel(Text(LocalizedStringKey("Settings")))
                        .accessibilityHint(Text(LocalizedStringKey("Open app settings for units, language, and premium features")))
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

    /// Top quick-switch bar: a dropdown of the user's top 3 favorited
    /// mountains, plus a "More…" entry that opens the full picker. Only
    /// shown when at least one mountain is favorited and no session is live.
    private var quickSwitchBar: some View {
        Menu {
            ForEach(quickSwitchMountains) { m in
                Button {
                    pendingSessionName = m.name_ja
                } label: {
                    Label("\(m.name_ja) · \(m.elevation_m) m", systemImage: "star.fill")
                }
            }
            Divider()
            Button {
                showMountainList = true
            } label: {
                Label(
                    String(localized: "japan_mountains_choose_button"),
                    systemImage: "list.bullet"
                )
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mountain.2")
                Text(LocalizedStringKey("Quick switch")).font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "chevron.down").font(.caption)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(Text(LocalizedStringKey("Quick switch")))
    }

    private var readouts: some View {
        HStack(spacing: 16) {
            readoutCard(titleKey: "Altitude",
                        value: store.altitudeUnit.formatted(store.current?.relativeAltitude ?? 0),
                        icon: "mountain.2")
            readoutCard(titleKey: "Pressure",
                        value: store.pressureUnit.formatted(kPa: store.current?.pressure ?? 0),
                        icon: "barometer")
        }
    }

    private func readoutCard(titleKey: LocalizedStringKey, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(titleKey, systemImage: icon).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .contentTransition(.numericText())
                .accessibilityValue(value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(titleKey)
    }

    private var chartCard: some View {
        let readings = store.liveSession?.readings ?? []
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(LocalizedStringKey("Live altitude"), systemImage: "waveform.path.ecg").font(.caption).foregroundStyle(.secondary)
                Spacer()
                if let s = store.liveSession {
                    Text(s.startedAt, style: .timer)
                        .font(.caption.monospacedDigit())
                        .accessibilityLabel(Text(LocalizedStringKey("Session duration")))
                }
            }
            if readings.isEmpty {
                ContentUnavailableView(LocalizedStringKey("Press Start to record"), systemImage: "play.circle")
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
                .accessibilityLabel(Text(LocalizedStringKey("Live altitude chart")))
                .accessibilityHint(Text(LocalizedStringKey("Shows altitude changes over time for the current session")))
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
                    TextField(LocalizedStringKey("Session name (optional)"), text: $pendingSessionName)
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
                    .accessibilityLabel(Text(LocalizedStringKey("japan_mountains_choose_button")))
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
                    Label(LocalizedStringKey("Start"), systemImage: "play.fill").frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent)
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(Text(LocalizedStringKey("Start recording")))
                .accessibilityHint(Text(LocalizedStringKey("Begins a new altitude tracking session")))
            } else {
                Button {
                    Haptics.medium()
                    let savedSession = store.stopAndReturnSavedSession()
                    Haptics.success()
                    if iap.isPremium,
                       UserDefaults.standard.bool(forKey: "syncAltitudeToAppleHealth"),
                       let s = savedSession {
                        Task { await HealthService.shared.saveSessionAsWorkout(s) }
                    }
                } label: {
                    Label(LocalizedStringKey("Stop"), systemImage: "stop.fill").frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.borderedProminent).tint(.red)
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(Text(LocalizedStringKey("Stop recording")))
                .accessibilityHint(Text(LocalizedStringKey("Ends the current session and saves it")))

                Button {
                    Haptics.light()
                    store.reset()
                } label: {
                    Label(LocalizedStringKey("Reset"), systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity).padding()
                }
                .buttonStyle(.bordered)
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(Text(LocalizedStringKey("Reset session")))
                .accessibilityHint(Text(LocalizedStringKey("Stops and immediately restarts the current recording")))
            }
            } // end HStack(spacing: 12)
        } // end VStack
    }

    private var unsupportedDevice: some View {
        ContentUnavailableView {
            Label(LocalizedStringKey("No barometric sensor"), systemImage: "exclamationmark.triangle")
        } description: {
            Text(LocalizedStringKey("AltitudeNow needs a device with a barometric pressure sensor. iPhone 6 and newer all have one. The iOS Simulator does not."))
        }
    }
}

#Preview {
    ContentView()
        .environment(AltimeterStore())
        .environment(IAPManager())
}
