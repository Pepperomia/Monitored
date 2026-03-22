import Foundation
import Combine

class LogsStore: ObservableObject {
    
    static let shared = LogsStore()
    
    @Published var logs: [String] = []
    
    func add(_ text: String) {
        DispatchQueue.main.async {
            self.logs.append(text)
        }
    }
    
    func clear() {
        logs.removeAll()
    }
}
