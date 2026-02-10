//
//  MainTabView.swift
//  Hype Buddy
//
//  Main tab navigation with CustomTabBar
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var subscriptionManager = SubscriptionManager()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView(subscriptionManager: subscriptionManager)
                case 1:
                    HistoryView(subscriptionManager: subscriptionManager)
                case 2:
                    SettingsView(subscriptionManager: subscriptionManager)
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [HypeSession.self, UserProfile.self], inMemory: true)
}
