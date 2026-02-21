import SwiftUI
import SwiftData

extension Color {
    static let appBackground = Color(red: 0.05, green: 0.1, blue: 0.25)
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    init() {
        let darkBlue = UIColor(red: 0.05, green: 0.1, blue: 0.25, alpha: 1.0)
        
        // Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = darkBlue
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // Tab Bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = darkBlue
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
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
        .preferredColorScheme(.dark)
        .tint(.white)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ExpenseReceipt.self, inMemory: true)
}
