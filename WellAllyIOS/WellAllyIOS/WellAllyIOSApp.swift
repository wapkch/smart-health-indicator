import SwiftUI

@main
struct WellAllyIOSApp: App {
    @State private var settings = AISettingsStore(keychain: KeychainService())
    private let healthStore = DemoHealthDataStore()

    var body: some Scene {
        WindowGroup {
            ContentView(healthStore: healthStore)
                .environment(settings)
        }
    }
}
