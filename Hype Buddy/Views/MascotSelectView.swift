//
//  MascotSelectView.swift
//  Hype Buddy
//
//  Mascot selection and unlock screen
//

import SwiftUI
import SwiftData

struct MascotSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var userProfile: UserProfile
    
    @State private var selectedMascot: Mascot = .sparky
    
    private var currentMascot: Mascot {
        Mascot(rawValue: userProfile.selectedMascot) ?? .sparky
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Header
                        headerSection
                        
                        // Mascot Cards
                        mascotCards
                        
                        // Action Button
                        if selectedMascot != currentMascot {
                            selectButton
                        }
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("Choose Your Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(Theme.Typography.body.bold())
                    .foregroundStyle(Theme.Colors.primary)
                }
            }
            .onAppear {
                selectedMascot = currentMascot
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Pick Your Hype Style")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Text("Each buddy has a unique personality")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
    
    // MARK: - Mascot Cards
    
    private var mascotCards: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(Mascot.allCases) { mascot in
                MascotCard(
                    mascot: mascot,
                    isSelected: selectedMascot == mascot,
                    isUnlocked: userProfile.isMascotUnlocked(mascot.rawValue),
                    isActive: currentMascot == mascot,
                    totalWins: userProfile.totalWins
                ) {
                    if userProfile.isMascotUnlocked(mascot.rawValue) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMascot = mascot
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Select Button
    
    private var selectButton: some View {
        CustomButton(
            title: "Select \(selectedMascot.name)",
            icon: "checkmark.circle.fill",
            style: .threeDimensional(color: selectedMascot.color),
            isDisabled: !userProfile.isMascotUnlocked(selectedMascot.rawValue)
        ) {
            userProfile.selectedMascot = selectedMascot.rawValue
            dismiss()
        }
        .padding(.bottom, Theme.Spacing.lg)
    }
}

// MARK: - Mascot Card

struct MascotCard: View {
    let mascot: Mascot
    let isSelected: Bool
    let isUnlocked: Bool
    let isActive: Bool
    let totalWins: Int
    let onTap: () -> Void
    
    private var progressToUnlock: Double {
        guard mascot.unlockRequirement > 0 else { return 1.0 }
        return min(1.0, Double(totalWins) / Double(mascot.unlockRequirement))
    }
    
    var body: some View {
        Button(action: onTap) {
            CustomCard(padding: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.md) {
                    // Mascot Avatar
                    if isUnlocked {
                        Image(mascot.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Theme.Colors.border, lineWidth: 1))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.secondaryBackground)
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(mascot.name)
                                .font(Theme.Typography.headline)
                                .foregroundStyle(isUnlocked ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                            
                            if isActive {
                                Text("ACTIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(mascot.color)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(mascot.description)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if !isUnlocked {
                            Text("Unlock at \(mascot.unlockRequirement) wins")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.accent)
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    if isUnlocked {
                         Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isSelected ? mascot.color : Theme.Colors.textSecondary)
                    }
                }
                
                // Unlock Progress
                if !isUnlocked {
                    VStack(spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Theme.Colors.secondaryBackground)
                                    .frame(height: 6)
                                
                                Capsule()
                                    .fill(mascot.color)
                                    .frame(width: geometry.size.width * progressToUnlock, height: 6)
                            }
                        }
                        .frame(height: 6)
                        .padding(.top, 8)
                        
                        Text("\(totalWins)/\(mascot.unlockRequirement) wins")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16) // Match CustomCard radius
                    .stroke(isSelected ? mascot.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

// MARK: - Mascot Description Extension

extension Mascot {
    var description: String {
        switch self {
        case .sparky:
            return "Pure energy! Sparky brings maximum hype with explosive enthusiasm."
        case .boost:
            return "Smart & strategic. Boost uses data from your wins to fuel confidence."
        case .pep:
            return "Warm & caring. Pep focuses on your wellbeing with gentle encouragement."
        }
    }
}

#Preview {
    MascotSelectView(userProfile: UserProfile())
}
