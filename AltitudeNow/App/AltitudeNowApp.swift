import SwiftUI

@main
struct AltitudeNowApp: App {
    @State private var store = AltimeterStore()
    @State private var iap = IAPManager()
    @State private var l10n = LocalizationManager.shared

    init() {
        // EAGER init: force LocalizationManager.shared (Bundle.main swizzle) to run
        // before SwiftUI evaluates first Text(LocalizedStringKey) lookup.
        _ = LocalizationManager.shared

        // Snapshot mode: skip onboarding so UI tests land directly on the main screen.
        if ProcessInfo.processInfo.arguments.contains("-FASTLANE_SNAPSHOT") {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(iap)
                .environment(l10n)
                .environment(\.locale, l10n.currentLocale)
                .id(l10n.override)  // root rebuild; modal sheets ALSO need own .id (added in ContentView).
                                    // Without this SwiftUI caches Text(LocalizedStringKey(...))
                                    // resolutions and the new .lproj is never read.
                                    // Pairs with OverrideBundle swap in LocalizationManager.swift.
                .task { await iap.refresh() }
                .tint(.accentColor)
        }
    }
}
