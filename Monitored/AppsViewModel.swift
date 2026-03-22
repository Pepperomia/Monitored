import Foundation
import SwiftUI
import Combine  // ← ДОБАВЛЯЕМ ЭТОТ ИМПОРТ!

class AppsViewModel: ObservableObject {
    
    @Published var apps: [MonitoredApp] = []
    @Published var currentLog: String = ""
    
    private let saveKey = "monitored_apps"
    
    init() {
        loadApps()
        
        // Подписываемся на уведомления об обновлении даты
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAppDate(_:)),
            name: .didUpdateAppDate,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func addApp(_ app: MonitoredApp) {
        apps.append(app)
        saveApps()
    }
    
    func updateApp(_ updatedApp: MonitoredApp) {
        if let index = apps.firstIndex(where: { $0.id == updatedApp.id }) {
            apps[index] = updatedApp
            saveApps()
        }
    }
    
    func togglePause(_ app: MonitoredApp) {
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index].isPaused.toggle()
            saveApps()
        }
    }
    
    // MARK: - Notification Handler
    
    @objc private func updateAppDate(_ notification: Notification) {
        guard let appId = notification.object as? UUID else { return }
        
        DispatchQueue.main.async {
            if let index = self.apps.firstIndex(where: { $0.id == appId }) {
                self.apps[index].lastSignedDate = Date()
                self.saveApps()
                print("✅ Обновлена дата для приложения: \(self.apps[index].name)")
            }
        }
    }
    
    // MARK: - Persistence
    
    private func saveApps() {
        if let encoded = try? JSONEncoder().encode(apps) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadApps() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([MonitoredApp].self, from: data) {
            apps = decoded
        }
    }
}

// MARK: - Notification Name Extension
extension Notification.Name {
    static let didUpdateAppDate = Notification.Name("didUpdateAppDate")
}
