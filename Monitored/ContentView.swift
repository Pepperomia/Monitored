import SwiftUI
import Combine

struct ContentView: View {
    
    @StateObject private var vm = AppsViewModel()
    @State private var now = Date()
    
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        ZStack {
            AppBackground(state: petState)
            
            VStack(spacing: 0) {
                
                // 🐭 HEADER
                PetView(state: petState)
                    .id(petState)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                
                // 📜 LIST
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.apps) { app in
                            AppCardView(
                                app: app,
                                now: now,
                                onBuild: {
                                    BuildService.run(app: app)
                                },
                                onTogglePause: {
                                    vm.togglePause(app)
                                },
                                onShowLogs: { },
                                onEdit: {
                                    activeSheet = .edit(app)
                                }
                            )
                        }
                    }
                    .padding(16)
                }
                .frame(maxHeight: .infinity)
                
                Divider()
                
                // ➕ FOOTER
                Button(action: {
                    activeSheet = .add
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add App")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .padding(16)
            }
        }
        // ⏱ ОБНОВЛЕНИЕ ВРЕМЕНИ
        .onReceive(
            Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        ) { _ in
            now = Date()
        }
        
        // 🚀 СТАРТ МОНИТОРА (ВАЖНО — ТУТ)
        .onAppear {
            MonitorService.shared.start {
                vm.apps
            }
        }
        
        .frame(minWidth: 520, minHeight: 600)
        
        // 📄 SHEET
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
                
            case .add:
                AddAppView { newApp in
                    vm.addApp(newApp)
                    activeSheet = nil
                }
                
            case .edit(let app):
                AddAppView(existingApp: app) { updatedApp in
                    vm.updateApp(updatedApp)
                    activeSheet = nil
                }
            }
        }
    }
    
    // MARK: - 🐭 Pet State
    
    private var petState: PetState {
        
        let activeApps = vm.apps.filter { !$0.isPaused }
        
        if activeApps.isEmpty {
            return .sleeping
        }
        
        let states = activeApps.map { appStatus($0) }
        
        if states.contains(.expired) {
            return .panic
        }
        
        if states.contains(.warning) {
            return .warning
        }
        
        if states.allSatisfy({ $0 == .healthy }) {
            if activeApps.allSatisfy({ isFresh($0) }) {
                return .party
            }
            return .happy
        }
        
        return .happy
    }
    
    private func appStatus(_ app: MonitoredApp) -> AppStatus {
        
        guard let last = app.lastSignedDate else {
            return .expired
        }
        
        let days = Calendar.current.dateComponents([.day], from: last, to: now).day ?? 0
        
        if days >= 7 { return .expired }
        if days >= 5 { return .warning }
        
        return .healthy
    }
    
    private func isFresh(_ app: MonitoredApp) -> Bool {
        guard let last = app.lastSignedDate else { return false }
        
        let hours = now.timeIntervalSince(last) / 3600
        
        return hours < 3
    }
    // MARK: - Sheet State

    enum ActiveSheet: Identifiable {
        case add
        case edit(MonitoredApp)
        
        var id: String {
            switch self {
            case .add:
                return "add"
            case .edit(let app):
                return app.id.uuidString
            }
        }
    }
}
