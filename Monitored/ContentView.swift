import SwiftUI

struct ContentView: View {
    
    @StateObject private var vm = AppsViewModel()
    
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                
                // 🐭 HEADER (прибит к верху)
                PetView(state: petState)
                
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                
                
                // 📜 SCROLL (занимает всё свободное место)
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.apps) { app in
                            AppCardView(
                                app: app,
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
                .frame(maxHeight: .infinity) // 🔥 ВАЖНО
                
                Divider()
                
                // ➕ FOOTER (всегда снизу)
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
            
            // 🧾 Логи
        }
        .frame(minWidth: 520, minHeight: 600)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
        // 📄 ЕДИНЫЙ SHEET
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
                
            case .add:
                AddAppView(onSave: { newApp in
                    vm.addApp(newApp)
                    activeSheet = nil
                })
                
            case .edit(let app):
                AddAppView(existingApp: app) { updatedApp in
                    vm.updateApp(updatedApp)
                    activeSheet = nil
                }
            }
        }
    }
    
    // MARK: - Pet State
    
    private var petState: PetState {
        
        if vm.apps.allSatisfy({ $0.isPaused }) {
            return .sleeping
        }
        
        if vm.apps.contains(where: isExpired) {
            return .panic
        }
        
        if vm.apps.contains(where: isWarning) {
            return .warning
        }
        
        // 🎉 ВСЕ ОБНОВЛЕНЫ СЕГОДНЯ
        if vm.apps.allSatisfy({ isFresh($0) }) {
            return .party
        }
        return .happy
    }
    
    private func isFresh(_ app: MonitoredApp) -> Bool {
        guard let last = app.lastSignedDate else { return false }
        
        let hours = Calendar.current.dateComponents([.hour], from: last, to: Date()).hour ?? 0
        
        return hours < 3
    }
    
    private func isExpired(_ app: MonitoredApp) -> Bool {
        guard let last = app.lastSignedDate else { return true }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return days >= 7
    }
    
    private func isWarning(_ app: MonitoredApp) -> Bool {
        guard let last = app.lastSignedDate else { return false }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return days >= 5
    }
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
