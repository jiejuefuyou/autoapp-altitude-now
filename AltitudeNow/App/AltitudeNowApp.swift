import SwiftUI

@main
struct AltitudeNowApp: App {
    @State private var store = AltimeterStore()
    @State private var iap = IAPManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(iap)
                .task { await iap.refresh() }
                .tint(.accentColor)
        }
    }
}
