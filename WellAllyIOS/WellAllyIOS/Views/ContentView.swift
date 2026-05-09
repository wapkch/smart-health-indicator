import SwiftUI

struct ContentView: View {
    let healthStore: DemoHealthDataStore

    var body: some View {
        TabView {
            HomeView(store: healthStore)
                .tabItem {
                    Label("tab.home", systemImage: "heart.text.square")
                }

            RecordsView(store: healthStore)
                .tabItem {
                    Label("tab.records", systemImage: "doc.text.magnifyingglass")
                }

            AIView(store: healthStore)
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }

            FamilyView(store: healthStore)
                .tabItem {
                    Label("tab.family", systemImage: "person.3")
                }
        }
        .tint(WellAllyColor.primary)
    }
}

#Preview {
    ContentView(healthStore: DemoHealthDataStore())
        .environment(AISettingsStore(keychain: PreviewKeychainService()))
}
