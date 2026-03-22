import SwiftUI

enum AppStatus {
    case healthy
    case warning
    case expired
    case paused
}

struct AppCardView: View {
    
    let app: MonitoredApp
    let onBuild: () -> Void
    let onTogglePause: () -> Void
    let onShowLogs: () -> Void
    let onEdit: () -> Void
    
    @State private var pulse = false
    @State private var shake = false
    @State private var logsWindow: NSWindow?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack(alignment: .center, spacing: 12) {
                
                // 🧊 ИКОНКА (стабильная!)
                appIcon
                
                // 📝 ТЕКСТ
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }
                .layoutPriority(1)
                
                Spacer(minLength: 8)
                
                // ⚙️ КНОПКИ
                HStack(spacing: 8) {
                    
                    Button(action: onTogglePause) {
                        Image(systemName: app.isPaused ? "play.fill" : "pause.fill")
                    }
                    .frame(width: 32, height: 32)
                    
                    Button(action: onBuild) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .frame(width: 32, height: 32)
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                    }
                    .frame(width: 32, height: 32)
                }
            }
            
            progressBar
            
            HStack {
                Button("Логи") {
                    if logsWindow == nil {
                        let window = NSWindow(
                            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                            styleMask: [.titled, .closable, .resizable],
                            backing: .buffered,
                            defer: false
                        )

                        window.center()
                        window.title = "Logs"
                        window.contentView = NSHostingView(rootView: LogsView())

                        logsWindow = window
                    }

                    logsWindow?.makeKeyAndOrderFront(nil)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .scaleEffect(shake ? 1.02 : 1)
        .onAppear { startAnimations() }
        .onChange(of: status) {
            startAnimations()
        }
    }
    
    // MARK: - STATUS
    
    private var status: AppStatus {
        if app.isPaused { return .paused }
        if progress <= 0 { return .expired }
        if progress < 0.3 { return .warning }
        return .healthy
    }
    
    private var statusColor: Color {
        switch status {
        case .paused: return .gray
        case .expired: return .red
        case .warning: return .orange
        case .healthy: return .green
        }
    }
    
    private var statusText: String {
        switch status {
        case .paused: return "Paused"
        case .expired: return "Expired"
        case .warning: return "Almost dead"
        case .healthy: return "Healthy"
        }
    }
    
    // MARK: - ICON (💎 ВОТ ЗДЕСЬ ВСЯ МАГИЯ)
    
    private var appIcon: some View {
        ZStack {
            if let nsImage = loadIcon() {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 40, height: 40) // 🔒 фиксируем размер
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
        .clipped()
    }
    
    private func loadIcon() -> NSImage? {
        
        let cleaned = cleanPath(app.iconPath)
        
        guard FileManager.default.fileExists(atPath: cleaned) else {
            print("❌ файл не найден:", cleaned)
            return nil
        }
        
        return NSImage(contentsOfFile: cleaned)
    }
    
    private func cleanPath(_ path: String) -> String {
        path
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - PROGRESS
    
    private var progressBar: some View {
        ProgressView(value: progress)
            .tint(statusColor.opacity(0.6))
            .scaleEffect(pulse ? 1.02 : 1)
    }
    
    private var progress: Double {
        guard let last = app.lastSignedDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return max(0, min(1, Double(7 - days) / 7))
    }
    
    // MARK: - ANIMATIONS
    
    private func startAnimations() {
        
        pulse = false
        shake = false
        
        switch status {
            
        case .healthy:
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            
        case .expired:
            withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                shake = true
            }
            
        default:
            break
        }
    }
}
