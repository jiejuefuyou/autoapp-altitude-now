import SwiftUI

struct SettingsView: View {
    @Environment(AltimeterStore.self) private var store
    @Environment(IAPManager.self) private var iap
    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.dismiss) private var dismiss

    @AppStorage("syncAltitudeToAppleHealth") private var syncAltitudeToHealth: Bool = false

    @State private var showPaywall = false
    @State private var calibrationDraft: String = ""
    @State private var healthRequestInFlight = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section(LocalizedStringKey("Units")) {
                    Picker(LocalizedStringKey("Altitude"), selection: $store.altitudeUnit) {
                        ForEach(AltitudeUnit.allCases) { u in Text(u.rawValue).tag(u) }
                    }
                    .accessibilityLabel(Text(LocalizedStringKey("Altitude unit")))
                    .accessibilityHint(Text(LocalizedStringKey("Choose between meters and feet")))
                    Picker(LocalizedStringKey("Pressure"), selection: $store.pressureUnit) {
                        ForEach(PressureUnit.allCases) { u in Text(u.rawValue).tag(u) }
                    }
                    .accessibilityLabel(Text(LocalizedStringKey("Pressure unit")))
                    .accessibilityHint(Text(LocalizedStringKey("Choose between hPa and inHg")))
                }

                Section {
                    if iap.isPremium {
                        HStack {
                            Text(LocalizedStringKey("Offset (m)"))
                            Spacer()
                            TextField("0", text: $calibrationDraft)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onSubmit(applyCalibration)
                                .accessibilityLabel(Text(LocalizedStringKey("Calibration offset in meters")))
                                .accessibilityHint(Text(LocalizedStringKey("Enter a positive or negative offset to align altitude with a known reference point")))
                        }
                        Button(LocalizedStringKey("Apply"), action: applyCalibration)
                            .accessibilityLabel(Text(LocalizedStringKey("Apply calibration")))
                            .accessibilityHint(Text(LocalizedStringKey("Applies the entered offset to all altitude readings")))
                    if let mtnAlt = UserDefaults.standard.object(forKey: "altitudenow.lastMountain.elevation") as? Double,
                       let mtnName = UserDefaults.standard.string(forKey: "altitudenow.lastMountain.name"),
                       !mtnName.isEmpty {
                        Button {
                            // Set offset so (current relative + offset) == mtnAlt
                            let newOffset = mtnAlt - (store.current?.relativeAltitude ?? 0)
                            store.setCalibration(offsetMeters: newOffset)
                            calibrationDraft = String(format: "%.1f", newOffset)
                            Haptics.success()
                        } label: {
                            HStack {
                                Image(systemName: "mountain.2.fill")
                                    .foregroundStyle(.tint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(String(format: NSLocalizedString("calibration_autofill_set_from", comment: ""), mtnName))
                                        .font(.subheadline)
                                    Text(String(format: "%.0f m", mtnAlt))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .accessibilityLabel(Text(String(format: NSLocalizedString("calibration_autofill_set_from", comment: ""), mtnName)))
                        .accessibilityHint(Text(LocalizedStringKey("calibration_autofill_hint")))
                    }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label(LocalizedStringKey("Calibration is a Premium feature"), systemImage: "lock.fill")
                        }
                        .accessibilityLabel(Text(LocalizedStringKey("Calibration — Premium feature")))
                        .accessibilityHint(Text(LocalizedStringKey("Unlock Premium to add a calibration offset")))
                    }
                } header: {
                    Text(LocalizedStringKey("Calibration"))
                } footer: {
                    Text(LocalizedStringKey("Add a constant offset (in meters) to align the relative altitude with a known reference point."))
                }

                Section {
                    if iap.isPremium {
                        Toggle(isOn: Binding(
                            get: { syncAltitudeToHealth },
                            set: { newValue in handleHealthToggle(newValue) }
                        )) {
                            Label(
                                LocalizedStringKey("Sync altitude to Apple Health"),
                                systemImage: "heart.fill"
                            )
                        }
                        .disabled(healthRequestInFlight || !HealthService.isAvailable)
                        .accessibilityLabel(Text(LocalizedStringKey("Sync altitude to Apple Health")))
                        .accessibilityHint(Text(LocalizedStringKey("When enabled, finished sessions are saved as workouts in Apple Health")))
                        if !HealthService.isAvailable {
                            Text(LocalizedStringKey("Apple Health is not available on this device."))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label(
                                LocalizedStringKey("Sync altitude to Apple Health is a Premium feature"),
                                systemImage: "lock.fill"
                            )
                        }
                        .accessibilityLabel(Text(LocalizedStringKey("Apple Health sync — Premium feature")))
                        .accessibilityHint(Text(LocalizedStringKey("Unlock Premium to enable Apple Health integration")))
                    }
                } header: {
                    Text(LocalizedStringKey("Apple Health"))
                } footer: {
                    Text(LocalizedStringKey("When enabled, finished sessions are saved as workouts in Apple Health with your elevation gain."))
                }

                Section(LocalizedStringKey("Language")) {
                    LanguagePicker()
                }

                Section(LocalizedStringKey("Premium")) {
                    if iap.isPremium {
                        Label(LocalizedStringKey("Premium unlocked"), systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .accessibilityLabel(Text(LocalizedStringKey("Premium is active")))
                    } else {
                        Button { showPaywall = true } label: {
                            Label(LocalizedStringKey("Unlock Premium"), systemImage: "sparkles")
                        }
                        .accessibilityLabel(Text(LocalizedStringKey("Unlock Premium")))
                        .accessibilityHint(Text(LocalizedStringKey("Opens the purchase screen for calibration and Apple Health sync")))
                    }
                    Button(LocalizedStringKey("Restore Purchase")) { Task { await iap.restore() } }
                        .accessibilityLabel(Text(LocalizedStringKey("Restore purchase")))
                        .accessibilityHint(Text(LocalizedStringKey("Restores a previous Premium purchase on this Apple ID")))
                }

                Section(LocalizedStringKey("Sensor")) {
                    LabeledContent(LocalizedStringKey("Available"), value: AltimeterStore.isSensorAvailable ? String(localized: "Yes") : String(localized: "No"))
                        .accessibilityLabel(Text(LocalizedStringKey("Barometric sensor availability")))
                        .accessibilityValue(AltimeterStore.isSensorAvailable ? Text(LocalizedStringKey("Available")) : Text(LocalizedStringKey("Not available")))
                }

                Section(LocalizedStringKey("About")) {
                    LabeledContent(LocalizedStringKey("Version"), value: appVersion)
                    LabeledContent(LocalizedStringKey("Build"),   value: buildNumber)
                    Link(LocalizedStringKey("Privacy Policy"), destination: URL(string: "https://github.com/jiejuefuyou/autoapp-altitude-now/blob/main/PRIVACY.md")!)
                    Link(LocalizedStringKey("Terms of Use"), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Label(LocalizedStringKey("No data collected. Ever."), systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(Text("Settings"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(LocalizedStringKey("Done")) { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear {
                calibrationDraft = String(format: "%.1f", store.calibrationOffset)
            }
        }
    }

    private func applyCalibration() {
        let cleaned = calibrationDraft.replacingOccurrences(of: ",", with: ".")
        if let v = Double(cleaned) {
            store.setCalibration(offsetMeters: v)
        }
    }

    /// Toggle handler: when the user flips the switch on, request HealthKit
    /// authorization. Persist the toggle only if the request succeeds, so a
    /// denied permission doesn't leave the UI in an inconsistent state.
    private func handleHealthToggle(_ newValue: Bool) {
        if newValue {
            guard HealthService.isAvailable else { return }
            healthRequestInFlight = true
            Task {
                let granted = await HealthService.shared.requestAuthorization()
                await MainActor.run {
                    healthRequestInFlight = false
                    syncAltitudeToHealth = granted
                }
            }
        } else {
            syncAltitudeToHealth = false
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}

private struct LanguagePicker: View {
    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        Picker(LocalizedStringKey("Language"), selection: Binding(
            get: { l10n.override },
            set: { l10n.setOverride($0) }
        )) {
            Text(LocalizedStringKey("System default")).tag("")
            ForEach(LocalizationManager.supportedLanguages, id: \.self) { code in
                Text(LocalizationManager.displayName(for: code)).tag(code)
            }
        }
        .pickerStyle(.menu)
    }
}
