import SwiftUI

struct PetView: View {
    
    let state: PetState
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }
    
    private var imageName: String {
        switch state {
        case .happy: return "mouse_happy"
        case .warning: return "mouse_warning"
        case .panic: return "mouse_panic"
        case .sleeping: return "mouse_sleep"
        case .building: return "mouse_warning"
        case .party: return "mouse_party"
        }
    }
    
    private var title: String {
        switch state {
        case .happy: return "All good"
        case .warning: return "Careful..."
        case .panic: return "Fix me!"
        case .sleeping: return "Sleeping"
        case .building: return "Working..."
        case .party: return "Yaaay!"
        }
    }
}
