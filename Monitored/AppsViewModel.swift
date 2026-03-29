import Foundation
import SwiftUI
import Combine

class AppsViewModel: ObservableObject {
    
    @Published var apps: [MonitoredApp] = []
    @Published var currentLog: String = ""
    
    private let saveKey = "monitored_apps"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadApps()
        
        NotificationCenter.default.publisher(for: .didUpdateAppDate)
            .sink { [weak self] notification in
                guard let self = self,
                      let appId = notification.object as? UUID else { return }
                
                if let index = self.apps.firstIndex(where: { $0.id == appId }) {
                    self.apps[index].lastSignedDate = Date()
                    self.apps = self.apps
                    self.saveApps()
                    
                    print("📅 обновлено:", self.apps[index].name)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD
    
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
    
    func removeApp(_ app: MonitoredApp) {
        apps.removeAll { $0.id == app.id }
        saveApps()
    }
    
    // MARK: - Notification
    
    @objc private func updateAppDate(_ notification: Notification) {
        guard let appId = notification.object as? UUID else { return }
        
        if let index = apps.firstIndex(where: { $0.id == appId }) {
            apps[index].lastSignedDate = Date()
            
            // 💥 ВАЖНО: триггерим обновление UI
            apps = apps
            
            saveApps()
            
            print("📅 Обновлена дата:", apps[index].name)
        }
    }
    
    // MARK: - Status Logic (🐭 самое важное)
    
    func daysLeft(for app: MonitoredApp) -> Int {
        guard let last = app.lastSignedDate else { return 0 }
        
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        
        return max(0, 7 - days)
    }
    
    func statusText(for app: MonitoredApp) -> String {
        let days = daysLeft(for: app)
        
        if days >= 5 { return "Happy" }
        if days >= 3 { return "Careful..." }
        return "Almost dead"
    }
    
    func statusColor(for app: MonitoredApp) -> Color {
        let days = daysLeft(for: app)
        
        if days >= 5 { return .green }
        if days >= 3 { return .orange }
        return .red
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

// MARK: - Notification Name

extension Notification.Name {
    static let didUpdateAppDate = Notification.Name("didUpdateAppDate")
}
