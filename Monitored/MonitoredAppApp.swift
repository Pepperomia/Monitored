import SwiftUI
import UserNotifications

@main
struct MonitoredAppApp: App {
    
    init() {
        requestNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func requestNotifications() {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("🔔 Permission granted:", granted)
            
            if let error = error {
                print("❌ Notification error:", error)
            }
        }
    }
}
