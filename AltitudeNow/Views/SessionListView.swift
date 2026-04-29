import SwiftUI
import Charts

struct SessionListView: View {
    @Environment(AltimeterStore.self) private var store
    @Environment(IAPManager.self) private var iap
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false

    private var visibleSessions: [Session] {
        // Free tier sees only the most recent session; Premium sees all.
        iap.isPremium ? store.sessions : Array(store.sessions.prefix(1))
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.sessions.isEmpty {
                    ContentUnavailableView("No sessions yet", systemImage: "list.bullet.clipboard",
                                           description: Text("Start a recording to log altitude over time."))
                } else {
                    List {
                        ForEach(visibleSessions) { s in row(s) }
                            .onDelete(perform: delete)
                        if !iap.isPremium && store.sessions.count > 1 {
                            Section {
                                lockedRow
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if iap.isPremium && !store.sessions.isEmpty {
                        Button("Clear", role: .destructive) { store.clearSessions() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private func row(_ s: Session) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(s.displayTitle).font(.headline)
                Spacer()
                Text(durationString(s.duration)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                stat("max", store.altitudeUnit.formatted(s.maxAltitude))
                stat("min", store.altitudeUnit.formatted(s.minAltitude))
                stat("gain", store.altitudeUnit.formatted(s.altitudeGain))
            }
            if s.readings.count > 2 {
                Chart {
                    ForEach(s.readings) { r in
                        LineMark(x: .value("t", r.timestamp), y: .value("alt", r.relativeAltitude))
                            .interpolationMethod(.monotone)
                    }
                }
                .chartYAxis(.hidden).chartXAxis(.hidden)
                .frame(height: 60)
            }
        }
        .padding(.vertical, 4)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        HStack(spacing: 3) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.monospacedDigit())
        }
    }

    private var lockedRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("\(store.sessions.count - 1) older sessions hidden", systemImage: "lock.fill")
                .foregroundStyle(.secondary)
            Button("Unlock with Premium") { showPaywall = true }
                .font(.footnote.weight(.semibold))
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets {
            if let s = visibleSessions[safe: i] { store.deleteSession(s) }
        }
    }

    private func durationString(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
