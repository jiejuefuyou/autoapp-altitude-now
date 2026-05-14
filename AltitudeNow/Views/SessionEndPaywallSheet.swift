import SwiftUI

/// Shown to non-premium users 0.5 s after a meaningful session ends (peakAltitude > 50 m).
/// High-conversion moment: the user just finished a real hike and wants to see their data.
struct SessionEndPaywallSheet: View {
    let session: Session?
    let onUpgrade: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(LocalizedStringKey("session_end_paywall_title"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            if let s = session {
                Text(summaryText(s))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("session_end_paywall_headline"))
                    .font(.headline)
                Text(LocalizedStringKey("session_end_paywall_body"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            Button(LocalizedStringKey("session_end_paywall_upgrade_cta"), action: onUpgrade)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Text(LocalizedStringKey("session_end_paywall_upgrade_cta")))

            Button(LocalizedStringKey("session_end_paywall_dismiss"), action: onDismiss)
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Text(LocalizedStringKey("session_end_paywall_dismiss")))
        }
        .padding(24)
        .presentationDetents([.medium])
    }

    private func summaryText(_ s: Session) -> String {
        let interval = (s.endedAt ?? .now).timeIntervalSince(s.startedAt)
        let h = Int(interval) / 3600
        let m = (Int(interval) % 3600) / 60
        let durationStr = h > 0
            ? String(format: NSLocalizedString("session_end_paywall_duration_hm", comment: ""), h, m)
            : String(format: NSLocalizedString("session_end_paywall_duration_m", comment: ""), m)
        return String(
            format: NSLocalizedString("session_end_paywall_stats", comment: ""),
            s.maxAltitude,
            s.altitudeGain,
            durationStr
        )
    }
}

#Preview {
    SessionEndPaywallSheet(
        session: nil,
        onUpgrade: {},
        onDismiss: {}
    )
}
