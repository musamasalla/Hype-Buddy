//
//  HomeView.swift
//  Hype Buddy
//
//  UI Overhaul: Clean layout, 3D buttons, CustomCards
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @Bindable var subscriptionManager: SubscriptionManager
    
    @State private var userInput = ""
    @State private var selectedScenario: HypeScenario?
    @State private var isGeneratingHype = false
    @State private var showPaywall = false
    @State private var showMascotSelect = false
    @State private var currentHypeSession: HypeSession?
    @State private var showHypeView = false
    @State private var showVoiceChat = false
    @State private var voiceService = VoiceService()
    
    private var userProfile: UserProfile {
        if let existing = profiles.first {
            return existing
        }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        return newProfile
    }
    
    private var currentMascot: Mascot {
        Mascot(rawValue: userProfile.selectedMascot) ?? .sparky
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Header
                        headerSection
                        
                        // Mascot Card
                        CustomCard {
                            mascotSection
                        }
                        
                        // Scenario Selection
                        scenarioSection
                        
                        // Custom Input
                        customInputSection
                        
                        // Action Button
                        getHypeButton
                        
                        // Bottom spacing for tab bar
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .scrollIndicators(.hidden)
            }
            .navigationDestination(isPresented: $showHypeView) {
                if let session = currentHypeSession {
                    HypeView(
                        session: session,
                        mascot: currentMascot,
                        subscriptionManager: subscriptionManager
                    )
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(subscriptionManager: subscriptionManager)
            }
            .sheet(isPresented: $showMascotSelect) {
                MascotSelectView(userProfile: userProfile)
            }
            .fullScreenCover(isPresented: $showVoiceChat) {
                VoiceChatView(
                    mascot: currentMascot,
                    userProfile: userProfile,
                    geminiService: GeminiService.shared,
                    voiceService: voiceService,
                    modelContext: modelContext,
                    isPremium: subscriptionManager.isPremium
                )
            }
            .overlay(alignment: .bottomTrailing) {
                if !showVoiceChat {
                    Button {
                        showVoiceChat = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Theme.Colors.primary)
                            .clipShape(Circle())
                            .shadow(color: Theme.Colors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.trailing, Theme.Spacing.md)
                    .padding(.bottom, Theme.Spacing.md) // Adjust for tab bar if needed
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hype Buddy")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Text("Ready to crush it? 🔥")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            if !subscriptionManager.isPremium {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text("\(userProfile.freeUsesRemaining)")
                    }
                    .font(Theme.Typography.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.Colors.accent.opacity(0.2))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Mascot Section
    private var mascotSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(currentMascot.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(currentMascot.color.opacity(0.2), lineWidth: 2))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(currentMascot.name)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Text("Your Hype Partner")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                
                Button {
                    showMascotSelect = true
                } label: {
                    Text("Change Buddy")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Scenario Section
    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("What's up?")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                ForEach(HypeScenario.allCases) { scenario in
                    let isSelected = selectedScenario == scenario
                    
                    Button {
                        withAnimation {
                            selectedScenario = isSelected ? nil : scenario
                        }
                    } label: {
                        HStack {
                            Text(scenario.emoji)
                            Text(scenario.title)
                                .font(Theme.Typography.caption)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Theme.Colors.primary.opacity(0.1) : Theme.Colors.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
                        )
                        .foregroundStyle(isSelected ? Theme.Colors.primary : Theme.Colors.textPrimary)
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Input Section
    private var customInputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Or tell me details...")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            TextField("Presentation, Date, Big Game...", text: $userInput, axis: .vertical)
                .font(Theme.Typography.body)
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .lineLimit(3...4)
        }
    }
    
    // MARK: - Action Button
    private var getHypeButton: some View {
        CustomButton(
            title: isGeneratingHype ? "Creating Hype..." : "GET HYPED!",
            icon: isGeneratingHype ? nil : "flame.fill",
            style: .threeDimensional(color: currentMascot.color),
            isDisabled: !canGetHype,
            isLoading: isGeneratingHype
        ) {
            Task {
                await generateHype()
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }
    
    // MARK: - Logic
    private var canGetHype: Bool {
        let hasInput = selectedScenario != nil || !userInput.trimmingCharacters(in: .whitespaces).isEmpty
        let hasUsage = subscriptionManager.isPremium || userProfile.freeUsesRemaining > 0
        return hasInput && hasUsage
    }
    
    private func generateHype() async {
        if !subscriptionManager.isPremium && userProfile.freeUsesRemaining <= 0 {
            showPaywall = true
            return
        }
        
        isGeneratingHype = true
        
        do {
            let recentWins = MemoryService.getRecentWins(
                from: modelContext,
                isPremium: subscriptionManager.isPremium
            )
            
            let hypeText = try await GeminiService.shared.generateHype(
                scenario: selectedScenario,
                customInput: userInput.isEmpty ? nil : userInput,
                mascot: currentMascot,
                recentWins: recentWins
            )
            
            let session = HypeSession(
                scenario: selectedScenario?.title ?? "Custom",
                userInput: userInput.isEmpty ? (selectedScenario?.title ?? "Quick hype") : userInput,
                sparkyResponse: hypeText,
                mascotUsed: currentMascot.rawValue
            )
            
            modelContext.insert(session)
            userProfile.freeUsesRemaining = max(0, userProfile.freeUsesRemaining - (subscriptionManager.isPremium ? 0 : 1))
            userProfile.totalHypes += 1
            
            NotificationManager.shared.scheduleWinLogReminder(
                for: session.id,
                scenario: session.scenario
            )
            
            currentHypeSession = session
            showHypeView = true
            
            userInput = ""
            selectedScenario = nil
            
        } catch {
            print("Error: \(error)")
        }
        
        isGeneratingHype = false
    }
}

#Preview {
    HomeView(subscriptionManager: SubscriptionManager())
        .modelContainer(for: [HypeSession.self, UserProfile.self], inMemory: true)
}
