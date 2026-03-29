import Foundation

struct MonitoredApp: Identifiable, Codable {
    
    let id: UUID
    
    var name: String
    var scheme: String
    var projectPath: String
    var bundleId: String
    
    var iconPath: String  
    
    var lastSignedDate: Date?
    var isPaused: Bool
}
