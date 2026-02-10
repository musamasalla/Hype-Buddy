//
//  SettingsView.swift
//  Hype Buddy
//
//  App settings and subscription management
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @Bindable var subscriptionManager: SubscriptionManager
    
    @State private var showPaywall = false
    @State private var showResetConfirmation = false
    @State private var notificationsEnabled = true
    
    private var userProfile: UserProfile? {
        profiles.first
    }
    
    private var isPremium: Bool {
        subscriptionManager.isPremium
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                List {
                    // Subscription Section
                    subscriptionSection
                    
                    // Preferences Section
                    preferencesSection
                    
                    // Support Section
                    supportSection
                    
                    // About Section
                    aboutSection
                    
                    // Danger Zone
                    dangerZone
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView(subscriptionManager: subscriptionManager)
            }
            .confirmationDialog(
                "Reset All Data?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    resetAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete all your hype sessions, wins, and progress. This cannot be undone.")
            }
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        Section {
            if isPremium {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premium Active ✨")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        
                        Text("Unlimited hypes & full history")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("Active")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.success.opacity(0.2))
                        .clipShape(Capsule())
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Go Premium 🚀")
                                .font(Theme.Typography.headline)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            
                            Text("Unlimited hypes, all mascots, full history")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(subscriptionManager.monthlyPriceString + "/mo")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
            }
            
            Button {
                Task {
                    try? await subscriptionManager.restorePurchases()
                }
            } label: {
                HStack {
                    Text("Restore Purchases")
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .font(Theme.Typography.body)
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        } header: {
            Text("Subscription")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .listRowBackground(Theme.Colors.secondaryBackground)
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(Theme.Colors.accent)
                    Text("Win Log Reminders")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
            .tint(Theme.Colors.success)
            
            NavigationLink {
                MascotSelectView(userProfile: userProfile ?? UserProfile())
            } label: {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Theme.Colors.secondary)
                    Text("Manage Mascots")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    if let mascot = Mascot(rawValue: userProfile?.selectedMascot ?? "sparky") {
                        Text(mascot.emoji)
                    }
                }
            }
        } header: {
            Text("Preferences")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .listRowBackground(Theme.Colors.secondaryBackground)
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section {
            Link(destination: Config.supportURL) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(Theme.Colors.primary)
                    Text("Contact Support")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            
            Link(destination: Config.privacyURL) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(Theme.Colors.tertiary)
                    Text("Privacy Policy")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            
            Link(destination: Config.termsURL) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text("Terms of Service")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        } header: {
            Text("Support")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .listRowBackground(Theme.Colors.secondaryBackground)
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            
            if let profile = userProfile {
                HStack {
                    Text("Total Hypes")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Text("\(profile.totalHypes)")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                
                HStack {
                    Text("Total Wins")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Text("\(profile.totalWins)")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        } header: {
            Text("About")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .listRowBackground(Theme.Colors.secondaryBackground)
    }
    
    // MARK: - Danger Zone
    
    private var dangerZone: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Reset All Data")
                        .font(Theme.Typography.body)
                }
            }
        } header: {
            Text("Danger Zone")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .listRowBackground(Theme.Colors.secondaryBackground)
    }
    
    // MARK: - Logic
    
    private func resetAllData() {
        do {
            try modelContext.delete(model: HypeSession.self)
            try modelContext.delete(model: UserProfile.self)
            
            // Create fresh profile
            let newProfile = UserProfile()
            modelContext.insert(newProfile)
            
            NotificationManager.shared.clearAllNotifications()
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
}

#Preview {
    SettingsView(subscriptionManager: SubscriptionManager())
        .modelContainer(for: [HypeSession.self, UserProfile.self], inMemory: true)
}
