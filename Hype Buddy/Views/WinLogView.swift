//
//  WinLogView.swift
//  Hype Buddy
//
//  Post-event outcome logging
//

import SwiftUI
import SwiftData

struct WinLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @Bindable var session: HypeSession
    
    @State private var selectedOutcome: String?
    @State private var notes = ""
    @State private var showConfetti = false
    
    private var userProfile: UserProfile? {
        profiles.first
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
                        
                        // Outcome Buttons
                        outcomeButtons
                        
                        // Notes (optional)
                        notesSection
                        
                        // Save Button
                        saveButton
                    }
                    .padding(Theme.Spacing.md)
                }
                
                // Confetti overlay
                if showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("How'd it go?")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Text(session.scenario)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.Colors.secondaryBackground)
                .clipShape(Capsule())
        }
        .padding(.top, Theme.Spacing.lg)
    }
    
    // MARK: - Outcome Buttons
    
    private var outcomeButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            OutcomeButton(
                outcome: "win",
                emoji: "✅",
                label: "Win!",
                color: Theme.Colors.success,
                isSelected: selectedOutcome == "win"
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedOutcome = "win"
                }
            }
            
            OutcomeButton(
                outcome: "meh",
                emoji: "😐",
                label: "Meh",
                color: Theme.Colors.warning,
                isSelected: selectedOutcome == "meh"
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedOutcome = "meh"
                }
            }
            
            OutcomeButton(
                outcome: "tough",
                emoji: "😤",
                label: "Tough",
                color: Theme.Colors.secondary,
                isSelected: selectedOutcome == "tough"
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedOutcome = "tough"
                }
            }
        }
    }
    
    // MARK: - Notes
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Add notes (optional)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            
            TextField("What happened? How did you feel?", text: $notes, axis: .vertical)
                .font(Theme.Typography.body)
                .padding()
                .background(Theme.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        CustomButton(
            title: "Save Outcome",
            style: .threeDimensional(color: selectedOutcome != nil ? Theme.Colors.success : Theme.Colors.muted),
            isDisabled: selectedOutcome == nil
        ) {
            saveOutcome()
        }
        .padding(.top, Theme.Spacing.md)
    }
    
    // MARK: - Logic
    
    private func saveOutcome() {
        guard let outcome = selectedOutcome else { return }
        
        // Update session
        session.outcome = outcome
        session.outcomeNotes = notes.isEmpty ? nil : notes
        
        // Update profile if win
        if outcome == "win", let profile = userProfile {
            profile.totalWins += 1
        }
        
        // Cancel the reminder notification
        NotificationManager.shared.cancelWinLogReminder(for: session.id)
        
        // Show confetti for wins
        if outcome == "win" {
            showConfetti = true
            
            // Dismiss after confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } else {
            dismiss()
        }
    }
}

// MARK: - Outcome Button

struct OutcomeButton: View {
    let outcome: String
    let emoji: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            CustomCard(
                padding: Theme.Spacing.md,
                backgroundColor: isSelected ? color.opacity(0.2) : Theme.Colors.secondaryBackground
            ) {
                VStack(spacing: Theme.Spacing.sm) {
                    Text(emoji)
                        .font(.system(size: 44))
                    
                    Text(label)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(isSelected ? color : Theme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [(id: Int, x: CGFloat, delay: Double)] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    Text(["🎉", "✨", "🔥", "⭐️", "💪"].randomElement()!)
                        .font(.title)
                        .offset(x: particle.x)
                        .modifier(FallingModifier(delay: particle.delay, height: geometry.size.height))
                }
            }
        }
        .onAppear {
            particles = (0..<20).map { i in
                (id: i, x: CGFloat.random(in: -150...150), delay: Double.random(in: 0...0.5))
            }
        }
    }
}

struct FallingModifier: ViewModifier {
    let delay: Double
    let height: CGFloat
    
    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 1
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 1.5).delay(delay)) {
                    offset = height + 100
                    opacity = 0
                }
            }
    }
}

#Preview {
    WinLogView(
        session: HypeSession(
            scenario: "Job Interview",
            userInput: "Big tech company",
            sparkyResponse: "You've got this!"
        )
    )
    .modelContainer(for: [HypeSession.self, UserProfile.self], inMemory: true)
}
