import SwiftUI

struct LogsView: View {
    
    @ObservedObject var store = LogsStore.shared
    
    var body: some View {
        VStack {
            
            if store.logs.isEmpty {
                
                VStack(spacing: 12) {
                    Image("mouse_sleep") // 🐭 твоя мышка
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                    
                    Text("Пока тихо...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            } else {
                
                ScrollViewReader { proxy in
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            
                            ForEach(store.logs.indices, id: \.self) { i in
                                Text(store.logs[i])
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id(i)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: store.logs.count) {
                        withAnimation {
                            proxy.scrollTo(store.logs.count - 1, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(.ultraThinMaterial)
    }
}
