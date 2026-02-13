//
//  HomeView.swift
//  Hype Buddy
//
//  UI Overhaul: Gradient backgrounds, floating particles, breathing mascot
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
    @State private var showTextChat = false
    @State private var voiceService = VoiceService()
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var mascotBreathing = false
    @State private var fabGlowing = false
    
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
                // Gradient background
                Theme.Gradients.home
                    .ignoresSafeArea()
                
                // Floating ambient particles
                FloatingParticlesView(
                    emojis: ["🔥", "✨", "⭐️", "💪"],
                    count: 8
                )
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
                        
                        // Bottom spacing
                        Spacer(minLength: 16)
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
            .fullScreenCover(isPresented: $showTextChat) {
                TextChatView(
                    mascot: currentMascot,
                    userProfile: userProfile,
                    geminiService: GeminiService.shared,
                    voiceService: voiceService,
                    modelContext: modelContext,
                    isPremium: subscriptionManager.isPremium
                )
            }
            .alert("Oops!", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay(alignment: .bottomTrailing) {
                if !showVoiceChat && !showTextChat {
                    VStack(spacing: 12) {
                        // Text chat FAB
                        Button {
                            showTextChat = true
                        } label: {
                            Image(systemName: "keyboard")
                                .font(.body)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(currentMascot.color.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(color: currentMascot.color.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                        
                        // Voice chat FAB (existing)
                        Button {
                            showVoiceChat = true
                        } label: {
                            ZStack {
                                // Glow ring
                                Circle()
                                    .fill(currentMascot.color.opacity(fabGlowing ? 0.3 : 0.0))
                                    .frame(width: 76, height: 76)
                                    .animation(
                                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                        value: fabGlowing
                                    )
                                
                                Image(systemName: "mic.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .frame(width: 60, height: 60)
                                    .background(currentMascot.color)
                                    .clipShape(Circle())
                                    .shadow(color: currentMascot.color.opacity(0.4), radius: 10, x: 0, y: 5)
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.trailing, Theme.Spacing.md)
                    .padding(.bottom, 90)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                fabGlowing = true
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
                    .background(.ultraThinMaterial)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Mascot Card
    private var mascotSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(currentMascot.emoji)
                .font(.system(size: 60))
                .scaleEffect(mascotBreathing ? 1.05 : 0.95)
                .animation(
                    .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: mascotBreathing
                )
                .onAppear { mascotBreathing = true }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(currentMascot.name)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Text("Your hype companion")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            Button {
                showMascotSelect = true
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(currentMascot.color)
                    .frame(width: 40, height: 40)
                    .background(currentMascot.color.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Scenarios
    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("What's on your mind?")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.Spacing.sm),
                GridItem(.flexible(), spacing: Theme.Spacing.sm)
            ], spacing: Theme.Spacing.sm) {
                ForEach(HypeScenario.allCases) { scenario in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedScenario = selectedScenario == scenario ? nil : scenario
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(scenario.emoji)
                            Text(scenario.title)
                                .font(Theme.Typography.subheadline)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(
                            selectedScenario == scenario
                            ? currentMascot.color.opacity(0.12)
                            : Color.clear
                        )
                        .background(.ultraThinMaterial)
                        .foregroundStyle(
                            selectedScenario == scenario
                            ? currentMascot.color
                            : Theme.Colors.textPrimary
                        )
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    selectedScenario == scenario
                                    ? currentMascot.color.opacity(0.4)
                                    : Color.white.opacity(0.1),
                                    lineWidth: 0.5
                                )
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Custom Input
    private var customInputSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Add details (optional)")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textSecondary)
            
            TextField("e.g. I'm about to give a big presentation...", text: $userInput, axis: .vertical)
                .lineLimit(3...5)
                .padding(Theme.Spacing.sm)
                .background(.ultraThinMaterial)
                .clipShape(.rect(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
    
    // MARK: - Get Hype Button
    private var getHypeButton: some View {
        CustomButton(
            title: "Get Hyped! 🔥",
            icon: "flame.fill",
            style: .threeDimensional(color: currentMascot.color),
            isDisabled: !canGetHype,
            isLoading: isGeneratingHype
        ) {
            generateHype()
        }
    }
    
    // MARK: - Logic
    
    private var canGetHype: Bool {
        selectedScenario != nil && !isGeneratingHype &&
        (subscriptionManager.isPremium || userProfile.freeUsesRemaining > 0)
    }
    
    private func generateHype() {
        guard let scenario = selectedScenario else { return }
        
        isGeneratingHype = true
        
        Task {
            do {
                let response = try await GeminiService.shared.generateHype(
                    scenario: scenario,
                    customInput: userInput.isEmpty ? nil : userInput,
                    mascot: currentMascot,
                    recentWins: []
                )
                
                let session = HypeSession(
                    scenario: scenario.rawValue,
                    userInput: userInput,
                    sparkyResponse: response,
                    mascotUsed: currentMascot.rawValue
                )
                
                modelContext.insert(session)
                currentHypeSession = session
                
                if !subscriptionManager.isPremium {
                    userProfile.freeUsesRemaining -= 1
                }
                
                isGeneratingHype = false
                showHypeView = true
                userInput = ""
                
            } catch {
                isGeneratingHype = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
