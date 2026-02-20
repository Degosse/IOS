import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet.rectangle.portrait")
                }
                .tag(0)
            
            ScanView(switchToHistory: {
                selectedTab = 0
            })
                .tabItem {
                    Label("Scan", systemImage: "camera")
                }
                .tag(1)
            
            OverviewView()
                .tabItem {
                    Label("Overview", systemImage: "chart.bar.doc.horizontal")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ExpenseReceipt.self, inMemory: true)
}
