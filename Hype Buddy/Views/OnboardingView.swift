//
//  OnboardingView.swift
//  Hype Buddy
//
//  First-time user onboarding experience
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool
    
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var selectedMascot: Mascot = .sparky
    
    private let pages = [
        OnboardingPage(
            emoji: "🔥",
            title: "Welcome to Hype Buddy",
            subtitle: "Your personal pep talk companion for life's big moments"
        ),
        OnboardingPage(
            emoji: "🎤",
            title: "Voice-Powered Hype",
            subtitle: "Get energizing pep talks before presentations, interviews, workouts & more"
        ),
        OnboardingPage(
            emoji: "🏆",
            title: "Track Your Wins",
            subtitle: "Log outcomes and watch your confidence grow with every victory"
        )
    ]
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count {
                        Button("Skip") {
                            withAnimation {
                                currentPage = pages.count
                            }
                        }
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding()
                    }
                }
                
                Spacer()
                
                // Content
                if currentPage < pages.count {
                    // Info pages
                    infoPageView(pages[currentPage])
                } else if currentPage == pages.count {
                    // Mascot selection
                    mascotSelectionView
                } else {
                    // Final ready screen
                    readyView
                }
                
                Spacer()
                
                // Navigation
                VStack(spacing: Theme.Spacing.md) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<(pages.count + 2), id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Theme.Colors.primary : Theme.Colors.muted)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, Theme.Spacing.sm)
                    
                    // Continue button
                    CustomButton(
                        title: currentPage == pages.count + 1 ? "Let's Go! 🚀" : "Continue",
                        style: .threeDimensional(color: Theme.Colors.primary)
                    ) {
                        withAnimation(.spring(response: 0.4)) {
                            if currentPage < pages.count + 1 {
                                currentPage += 1
                            } else {
                                completeOnboarding()
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }
    
    // MARK: - Info Page
    
    private func infoPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text(page.emoji)
                .font(.system(size: 80))
            
            Text(page.title)
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(page.subtitle)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Mascot Selection
    
    private var mascotSelectionView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Meet Your Buddy")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Text("Sparky is here to hype you up!")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
            
            // Sparky preview
            CustomCard {
                VStack(spacing: Theme.Spacing.md) {
                    Image(Mascot.sparky.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    
                    Text("Sparky")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.primary)
                    
                    Text("Pure energy! Maximum hype with explosive enthusiasm.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            
            Text("Unlock more buddies as you log wins!")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Ready View
    
    private var readyView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("🔥")
                .font(.system(size: 80))
            
            Text("You're All Set!")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Text("Get ready to crush your next big moment")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            CustomCard {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    FeatureCheck(text: "5 free hypes per week")
                    FeatureCheck(text: "Unlock new mascots with wins")
                    FeatureCheck(text: "AI-powered personalized pep talks")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Logic
    
    private func completeOnboarding() {
        // Create user profile if needed
        let profile = UserProfile(selectedMascot: selectedMascot.rawValue)
        modelContext.insert(profile)
        
        // Request notification permission
        Task {
            await NotificationManager.shared.requestPermission()
        }
        
        // Mark onboarding complete
        hasCompletedOnboarding = true
    }
}

// MARK: - Supporting Types

struct OnboardingPage {
    let emoji: String
    let title: String
    let subtitle: String
}

struct FeatureCheck: View {
    let text: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.success)
            Text(text)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
