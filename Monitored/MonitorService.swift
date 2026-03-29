import Foundation
import AppKit
import UserNotifications

class MonitorService {
    
    static let shared = MonitorService()
    
    private var timer: Timer?
    private var isRunning = false
    private var appsProvider: (() -> [MonitoredApp])?
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBuildFinished),
            name: .didUpdateAppDate,
            object: nil
        )
    }
    
    // MARK: - Start
    
    func start(appsProvider: @escaping () -> [MonitoredApp]) {
        
        self.appsProvider = appsProvider
        
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.runCheck()
        }
        
        runCheck()
    }
    
    private func runCheck() {
        guard let apps = appsProvider?() else { return }
        check(apps: apps)
    }
    
    // MARK: - Logic
    
    private func check(apps: [MonitoredApp]) {
        
        for app in apps where !app.isPaused {
            
            let last = app.lastSignedDate ?? Date(timeIntervalSince1970: 0)
            let nextUpdate = Calendar.current.date(byAdding: .day, value: 6, to: last)!
            
            print("🔍", app.name, "next:", nextUpdate)
            
            if Date() >= nextUpdate && !isRunning {
                triggerUpdate(app: app)
            }
        }
    }
    
    private func triggerUpdate(app: MonitoredApp) {
        
        if isRunning { return }
        
        isRunning = true
        
        print("🚀 старт обновления:", app.name)
        
        notifyNeedUpdate(app: app)
        waitForDeviceAndRun(app: app)
    }
    
    private func waitForDeviceAndRun(app: MonitoredApp) {
        
        DispatchQueue.global().async {
            
            print("🔌 ждём устройство...")
            
            while !BuildService.isDeviceConnected() {
                sleep(5)
            }
            
            print("📱 подключено")
            
            DispatchQueue.main.async {
                BuildService.run(app: app)
            }
        }
    }
    
    // MARK: - Finish (🔥 КЛЮЧЕВОЕ)
    
    @objc private func handleBuildFinished(_ notification: Notification) {
        
        guard let id = notification.object as? UUID else { return }
        
        print("🏁 билд завершён для:", id)
        
        isRunning = false
    }
    
    // MARK: - Notifications
    
    private func notifyNeedUpdate(app: MonitoredApp) {
        
        let content = UNMutableNotificationContent()
        content.title = "Пора обновить"
        content.body = "\(app.name) требует обновления 📱"
        
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
        )
        
        print("🔔 need update:", app.name)
    }
}
