import SwiftUI

struct AddAppView: View {
    
    var existingApp: MonitoredApp? = nil
    var onSave: (MonitoredApp) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: - State
    
    @State private var name = ""
    @State private var scheme = ""
    @State private var projectPath = ""
    @State private var bundleId = ""
    @State private var iconPath = ""   // 👈 новое поле
    
    var body: some View {
        VStack(spacing: 16) {
            
            Text(existingApp == nil ? "Добавить приложение" : "Редактировать")
                .font(.headline)
            
            // MARK: - Fields
            
            TextField("Название", text: $name)
            TextField("Scheme", text: $scheme)
            TextField("Путь к .xcodeproj", text: $projectPath)
            TextField("Bundle ID", text: $bundleId)
            TextField("Путь к иконке (png/jpg)", text: $iconPath) // 👈 вот он
            
            // MARK: - Save
            
            Button("Сохранить") {
                saveApp()
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            loadExistingData()
        }
    }
    
    // MARK: - Load existing
    
    private func loadExistingData() {
        guard let app = existingApp else { return }
        
        name = app.name
        scheme = app.scheme
        projectPath = app.projectPath
        bundleId = app.bundleId
        iconPath = app.iconPath   // 👈 важно
    }
    
    // MARK: - Save
    
    private func saveApp() {
        
        let app = MonitoredApp(
            id: existingApp?.id ?? UUID(),
            name: name,
            scheme: scheme,
            projectPath: projectPath,
            bundleId: bundleId,
            iconPath: iconPath, // 👈 главное изменение
            lastSignedDate: existingApp?.lastSignedDate,
            isPaused: existingApp?.isPaused ?? false
        )
        
        onSave(app)
        dismiss()
    }
}
