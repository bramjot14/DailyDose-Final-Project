import SwiftUI

@main
struct DailyDoseApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(store)
                .onAppear {
                    store.requestNotificationPermission()
                }
        }
    }
}
