import SwiftUI

struct SettingsView: View {
    @Environment(AltimeterStore.self) private var store
    @Environment(IAPManager.self) private var iap
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var calibrationDraft: String = ""

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Altitude", selection: $store.altitudeUnit) {
                        ForEach(AltitudeUnit.allCases) { u in Text(u.rawValue).tag(u) }
                    }
                    Picker("Pressure", selection: $store.pressureUnit) {
                        ForEach(PressureUnit.allCases) { u in Text(u.rawValue).tag(u) }
                    }
                }

                Section {
                    if iap.isPremium {
                        HStack {
                            Text("Offset (m)")
                            Spacer()
                            TextField("0", text: $calibrationDraft)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onSubmit(applyCalibration)
                        }
                        Button("Apply", action: applyCalibration)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Calibration is a Premium feature", systemImage: "lock.fill")
                        }
                    }
                } header: {
                    Text("Calibration")
                } footer: {
                    Text("Add a constant offset (in meters) to align the relative altitude with a known reference point.")
                }

                Section("Premium") {
                    if iap.isPremium {
                        Label("Premium unlocked", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    } else {
                        Button { showPaywall = true } label: {
                            Label("Unlock Premium", systemImage: "sparkles")
                        }
                    }
                    Button("Restore Purchase") { Task { await iap.restore() } }
                }

                Section("Sensor") {
                    LabeledContent("Available", value: AltimeterStore.isSensorAvailable ? "Yes" : "No")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build",   value: buildNumber)
                    Link("Privacy Policy", destination: URL(string: "https://github.com/jiejuefuyou/autoapp-altitude-now/blob/main/PRIVACY.md")!)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}
