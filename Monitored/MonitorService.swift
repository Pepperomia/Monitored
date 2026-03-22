import Foundation
import AppKit
import UserNotifications

class MonitorService {
    
    static let shared = MonitorService()
    
    private var timer: Timer?
    private var isRunning = false
    private var appsProvider: (() -> [MonitoredApp])?
    
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
            
            // ПРАВИЛЬНЫЙ ТРИГГЕР
            if Date() >= nextUpdate {
                triggerUpdate(app: app)
            }
        }
    }
    
    private func triggerUpdate(app: MonitoredApp) {
        
        if isRunning {
            print("⏳ уже выполняется")
            return
        }
        
        print("🚀 старт обновления:", app.name)
        
        isRunning = true
        
        notifyNeedUpdate(app: app) // 👈 передаём app
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    
                    self.isRunning = false
                }
            }
        }
    }
    
    // MARK: - Notifications

    private func notifyNeedUpdate(app: MonitoredApp) {
        
        let content = UNMutableNotificationContent()
        content.title = "Пора обновить"
        content.body = "\(app.name) требует обновления 📱"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        
        print("🔔 need update:", app.name)
    }


    private func notifyDone(app: MonitoredApp) {
        
        let content = UNMutableNotificationContent()
        content.title = "Готово!"
        content.body = "\(app.name) обновлено 🎉"
        
        // 📦 Берём ИКОНКУ ИЗ ФАЙЛА
        let path = app.iconPath.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if FileManager.default.fileExists(atPath: path),
           let image = NSImage(contentsOfFile: path),
           let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) {
            
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString).png")
            
            try? pngData.write(to: url)
            
            if let attachment = try? UNNotificationAttachment(
                identifier: "icon",
                url: url,
                options: nil
            ) {
                content.attachments = [attachment]
            }
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
        
        print("🔔 done:", app.name)
    }
    
    // MARK: - Test
    
    func testNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Тест"
        content.body = "Если ты это видишь — всё работает 🎉"
        
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
        )
    }
}
