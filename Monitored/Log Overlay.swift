import SwiftUI

struct LogOverlayView: View {
    
    let logs: String
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Logs")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Close") {
                        onClose()
                    }
                }
                
                ScrollView {
                    Text(logs)
                        .font(.system(size: 11, design: .monospaced))
                        .padding()
                }
            }
            .padding()
            .frame(width: 600, height: 400)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
}
