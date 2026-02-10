//
//  PaywallView.swift
//  Hype Buddy
//
//  Premium subscription screen
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var subscriptionManager: SubscriptionManager
    
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Header
                        headerSection
                        
                        // Features
                        CustomCard {
                            featuresSection
                        }
                        
                        // Plan Selector
                        planSelector
                        
                        // Purchase Button
                        purchaseButton
                        
                        // Terms
                        termsSection
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Text("👑")
                    .font(.system(size: 40))
            }
            .padding(.bottom, Theme.Spacing.sm)
            
            Text("Go Premium")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Text("Unlock your full hype potential")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.top, Theme.Spacing.lg)
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Hypes",
                subtitle: "No weekly limits"
            )
            
            FeatureRow(
                icon: "person.3.fill",
                title: "All Mascots",
                subtitle: "Sparky, Boost & Pep unlocked"
            )
            
            FeatureRow(
                icon: "clock.fill",
                title: "Full History",
                subtitle: "Access all your past sessions"
            )
            
            FeatureRow(
                icon: "brain.head.profile",
                title: "Enhanced Memory",
                subtitle: "AI remembers more of your wins"
            )
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
    
    // MARK: - Plan Selector
    
    private var planSelector: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Monthly Plan
            PlanCard(
                plan: .monthly,
                price: subscriptionManager.monthlyPriceString,
                period: "month",
                isSelected: selectedPlan == .monthly,
                badge: nil
            ) {
                withAnimation {
                    selectedPlan = .monthly
                }
            }
            
            // Yearly Plan
            PlanCard(
                plan: .yearly,
                price: subscriptionManager.yearlyPriceString,
                period: "year",
                isSelected: selectedPlan == .yearly,
                badge: subscriptionManager.yearlySavings
            ) {
                withAnimation {
                    selectedPlan = .yearly
                }
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        VStack(spacing: Theme.Spacing.sm) {
            CustomButton(
                title: "Start Premium",
                icon: isPurchasing ? nil : "arrow.right",
                style: .threeDimensional(color: Theme.Colors.accent),
                isLoading: isPurchasing
            ) {
                Task {
                    await purchase()
                }
            }
            
            Button {
                Task {
                    try? await subscriptionManager.restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }
    
    // MARK: - Terms
    
    private var termsSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.md)
            
            HStack(spacing: Theme.Spacing.md) {
                Link("Privacy", destination: Config.privacyURL)
                Text("•")
                Link("Terms", destination: Config.termsURL)
            }
            .font(.system(size: 11))
            .foregroundStyle(Theme.Colors.primary)
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }
    
    // MARK: - Logic
    
    private func purchase() async {
        isPurchasing = true
        
        let product = selectedPlan == .monthly
            ? subscriptionManager.monthlyProduct
            : subscriptionManager.yearlyProduct
        
        guard let product else {
            errorMessage = "Product not available"
            showError = true
            isPurchasing = false
            return
        }
        
        do {
            try await subscriptionManager.purchase(product)
            dismiss()
        } catch SubscriptionError.userCancelled {
            // User cancelled, no error to show
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isPurchasing = false
    }
}

// MARK: - Subscription Plan

enum SubscriptionPlan {
    case monthly
    case yearly
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.Colors.accent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.Colors.success)
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: SubscriptionPlan
    let price: String
    let period: String
    let isSelected: Bool
    let badge: String?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            CustomCard(
                padding: Theme.Spacing.md,
                backgroundColor: isSelected ? Theme.Colors.accent.opacity(0.1) : Theme.Colors.secondaryBackground
            ) {
                VStack(spacing: Theme.Spacing.xs) {
                    if let badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.Colors.success)
                            .clipShape(Capsule())
                    } else {
                        Spacer().frame(height: 22)
                    }
                    
                    Text(plan == .monthly ? "Monthly" : "Yearly")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    
                    Text(price)
                        .font(Theme.Typography.title3)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    
                    Text("/\(period)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView(subscriptionManager: SubscriptionManager())
}
