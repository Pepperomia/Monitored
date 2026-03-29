import Foundation
import UserNotifications
import AppKit

class BuildService {
    
    static func run(app: MonitoredApp) {
        
        notifyStart(app: app)
        
        let process = Process()
        process.launchPath = "/bin/zsh"
        
        let projectPath = cleanPath(app.projectPath)
        let scheme = cleanPath(app.scheme)
        
        let command = """
        xcrun xcodebuild \
        -scheme "\(scheme)" \
        -configuration Debug \
        -project "\(projectPath)" \
        -destination 'id=00008110-00160DE10A50201E' \
        -allowProvisioningUpdates \
        build

        DERIVED_DATA=$(xcodebuild -project "\(projectPath)" -scheme "\(scheme)" -showBuildSettings | grep BUILD_DIR | head -n 1 | awk '{print $3}')

        APP_PATH=$(find "$DERIVED_DATA" -name "*.app" | head -n 1)

        echo "APP_PATH=$APP_PATH"

        if [ -z "$APP_PATH" ]; then
          echo "BUILD FAILED"
          exit 1
        fi

        /opt/homebrew/bin/ios-deploy \
        --id 00008110-00160DE10A50201E \
        --bundle "$APP_PATH" \
        --justlaunch

        echo "INSTALL ATTEMPT FINISHED"
        """
        
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        var outputBuffer = ""
        var didFinish = false
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            
            guard let text = String(data: data, encoding: .utf8),
                  !text.isEmpty else { return }
            
            outputBuffer += text
            print(text)
            
            // ✅ УСПЕХ — ТОЛЬКО если реально установилось
            if !didFinish &&
                (text.contains("InstallComplete") || text.contains("Installed package")) {
                
                didFinish = true
                
                DispatchQueue.main.async {
                    notifyDone(app: app)
                    
                    NotificationCenter.default.post(
                        name: .didUpdateAppDate,
                        object: app.id
                    )
                }
            }
            
            // ❌ ошибка сборки
            if !didFinish && text.contains("BUILD FAILED") {
                didFinish = true
                
                DispatchQueue.main.async {
                    notifyError(app: app)
                }
            }
        }
        
        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                print("🏁 Процесс завершён")
                
                if didFinish { return }
                
                // fallback (если stdout странный)
                if outputBuffer.contains("InstallComplete") ||
                    outputBuffer.contains("Installed package") {
                    
                    notifyDone(app: app)
                    
                    NotificationCenter.default.post(
                        name: .didUpdateAppDate,
                        object: app.id
                    )
                    
                } else {
                    notifyError(app: app)
                }
            }
        }
        
        process.launch()
    }
    
    // MARK: - Notifications
    
    static func notifyStart(app: MonitoredApp) {
        let content = UNMutableNotificationContent()
        content.title = "Привет! 😊"
        content.body = "Подключи iPhone для обновления \(app.name)"
        content.sound = .default
        
        send(content)
    }
    
    static func notifyDone(app: MonitoredApp) {
        let content = UNMutableNotificationContent()
        content.title = "Готово! 🎉"
        content.body = "\(app.name) обновлено"
        content.sound = .default
        
        send(content)
    }
    
    static func notifyError(app: MonitoredApp) {
        let content = UNMutableNotificationContent()
        content.title = "Ошибка 😬"
        content.body = "Не удалось обновить \(app.name)"
        content.sound = .default
        
        send(content)
    }
    
    private static func send(_ content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Device
    
    static func isDeviceConnected() -> Bool {
        
        let process = Process()
        process.launchPath = "/opt/homebrew/bin/ios-deploy"
        process.arguments = ["-c"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        process.launch()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return output.contains("Found")
    }
    
    // MARK: - Utils
    
    private static func cleanPath(_ path: String) -> String {
        path
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
