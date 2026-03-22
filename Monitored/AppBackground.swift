import SwiftUI

struct AppBackground: View {
    
    let state: PetState
    
    @State private var move = false
    
    var body: some View {
        ZStack {
            
            baseGradient
            
            // 🫧 ПЯТНА
            Circle()
                .fill(primaryColor.opacity(0.18))
                .frame(width: 320)
                .blur(radius: 90)
                .offset(x: move ? -180 : -120, y: move ? -220 : -160)
            
            Circle()
                .fill(secondaryColor.opacity(0.15))
                .frame(width: 260)
                .blur(radius: 80)
                .offset(x: move ? 200 : 140, y: move ? 240 : 180)
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 420)
                .blur(radius: 120)
                .offset(x: move ? 20 : -20, y: move ? 320 : 260)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                move.toggle()
            }
        }
    }
    
    // MARK: - COLORS
    
    private var primaryColor: Color {
        switch state {
        case .panic: return .red
        case .warning: return .orange
        case .happy: return .mint
        case .party: return .cyan
        case .sleeping: return .gray
        case .building: return .blue
        }
    }
    
    private var secondaryColor: Color {
        switch state {
        case .panic: return .pink
        case .warning: return .yellow
        case .happy: return .cyan
        case .party: return .mint
        case .sleeping: return .gray.opacity(0.6)
        case .building: return .teal
        }
    }
    
    private var baseGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.1, blue: 0.12),
                Color(red: 0.12, green: 0.15, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
