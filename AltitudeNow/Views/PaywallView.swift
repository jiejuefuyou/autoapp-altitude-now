import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(IAPManager.self) private var iap
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "barometer")
                        .font(.system(size: 56))
                        .foregroundStyle(.tint)
                        .padding(.top, 24)

                    Text("AltitudeNow Premium").font(.largeTitle.bold())

                    Text("One-time purchase. No subscription. Unlock everything forever.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        feature("infinity",         "Unlimited session history")
                        feature("chart.xyaxis.line","Detailed altitude charts")
                        feature("doc.text",         "CSV export")
                        feature("ruler",            "Custom calibration offset")
                        feature("ruler.fill",       "Imperial / metric units")
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    purchaseButton.padding(.horizontal)

                    Button("Restore Purchase") { Task { await iap.restore() } }.font(.footnote)

                    if let err = iap.lastError {
                        Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
                    }

                    Text(legalese)
                        .font(.caption2).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).padding(.horizontal).padding(.bottom)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } }
            }
            .onChange(of: iap.isPremium) { _, v in if v { dismiss() } }
            .task { await iap.loadProducts() }
        }
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if iap.isPremium {
            Label("Premium unlocked", systemImage: "checkmark.seal.fill")
                .font(.headline).frame(maxWidth: .infinity).padding()
                .background(Color.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.green)
        } else if let product = iap.products.first {
            Button { Task { await iap.purchase() } } label: {
                HStack {
                    if iap.purchaseInProgress { ProgressView().tint(.white) }
                    Text(iap.purchaseInProgress ? "Processing…" : "Unlock for \(product.displayPrice)").font(.headline)
                }
                .frame(maxWidth: .infinity).padding()
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
            }
            .disabled(iap.purchaseInProgress)
        } else {
            ProgressView().frame(maxWidth: .infinity).padding()
        }
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.tint).frame(width: 28)
            Text(text); Spacer()
        }
    }

    private var legalese: String {
        "Payment will be charged to your Apple ID. This is a one-time purchase that unlocks all premium features for the lifetime of your Apple ID."
    }
}

#Preview {
    PaywallView().environment(IAPManager())
}
