//
//  HistoryView.swift
//  Hype Buddy
//
//  Past hype sessions and wins
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HypeSession.timestamp, order: .reverse) private var sessions: [HypeSession]
    @Query private var profiles: [UserProfile]
    
    @Bindable var subscriptionManager: SubscriptionManager
    
    @State private var selectedFilter: HistoryFilter = .all
    @State private var showPaywall = false
    @State private var selectedSession: HypeSession?
    @State private var showWinLog = false
    
    private var isPremium: Bool {
        subscriptionManager.isPremium
    }
    
    private var filteredSessions: [HypeSession] {
        let filtered: [HypeSession]
        
        switch selectedFilter {
        case .all:
            filtered = Array(sessions)
        case .wins:
            filtered = sessions.filter { $0.outcome == "win" }
        case .pending:
            filtered = sessions.filter { $0.outcome == nil }
        }
        
        // Apply free tier limit
        if !isPremium && filtered.count > Config.freeHistoryLimit {
            return Array(filtered.prefix(Config.freeHistoryLimit))
        }
        
        return filtered
    }
    
    private var stats: (total: Int, wins: Int, winRate: Double) {
        let total = sessions.count
        let wins = sessions.filter { $0.outcome == "win" }.count
        let winRate = total > 0 ? Double(wins) / Double(total) * 100 : 0
        return (total, wins, winRate)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Spacing.lg) {
                            // Stats Cards
                            statsSection
                            
                            // Filter Picker
                            filterPicker
                            
                            // Session List
                            sessionList
                            
                            // Premium Upsell
                            if !isPremium && sessions.count > Config.freeHistoryLimit {
                                premiumUpsell
                            }
                            
                            Spacer(minLength: 16)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.md)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .background(Theme.Colors.background.ignoresSafeArea())
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showPaywall) {
                PaywallView(subscriptionManager: subscriptionManager)
            }
            .sheet(isPresented: $showWinLog) {
                if let session = selectedSession {
                    WinLogView(session: session)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("🔥")
                .font(.system(size: 80))
            
            Text("No hypes yet!")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Colors.textPrimary)
            
            Text("Get your first hype and start logging those wins!")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.sm) {
            StatCard(
                title: "Total",
                value: "\(stats.total)",
                icon: "flame.fill",
                color: Theme.Colors.secondary
            )
            
            StatCard(
                title: "Wins",
                value: "\(stats.wins)",
                icon: "checkmark.circle.fill",
                color: Theme.Colors.success
            )
            
            StatCard(
                title: "Rate",
                value: String(format: "%.0f%%", stats.winRate),
                icon: "chart.line.uptrend.xyaxis",
                color: Theme.Colors.accent
            )
        }
    }
    
    // MARK: - Filter Picker
    
    private var filterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(HistoryFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, Theme.Spacing.xs)
    }
    
    // MARK: - Session List
    
    private var sessionList: some View {
        LazyVStack(spacing: Theme.Spacing.sm) {
            ForEach(filteredSessions) { session in
                SessionCard(session: session)
                    .overlay(alignment: .bottomTrailing) {
                        if session.outcome == nil {
                            Text("Tap to log outcome")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.Colors.accent.opacity(0.85))
                                .clipShape(Capsule())
                                .padding(8)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if session.outcome == nil {
                            selectedSession = session
                            showWinLog = true
                        }
                    }
                    .contextMenu {
                        if session.outcome == nil {
                            Button {
                                selectedSession = session
                                showWinLog = true
                            } label: {
                                Label("Log Outcome", systemImage: "checkmark.circle")
                            }
                        }
                        
                        Button(role: .destructive) {
                            deleteSession(session)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
    
    // MARK: - Delete Session
    
    private func deleteSession(_ session: HypeSession) {
        // Decrement wins counter if deleting a win
        if session.outcome == "win", let profile = profiles.first {
            profile.totalWins = max(0, profile.totalWins - 1)
        }
        
        modelContext.delete(session)
        try? modelContext.save()
    }
    
    // MARK: - Premium Upsell
    
    private var premiumUpsell: some View {
        CustomButton(
            title: "See all \(sessions.count) sessions",
            icon: "lock.fill",
            style: .threeDimensional(color: Theme.Colors.accent)
        ) {
            showPaywall = true
        }
        .padding(.bottom, Theme.Spacing.lg)
    }
}

// MARK: - Filter Enum

enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case wins = "wins"
    case pending = "pending"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: return "All"
        case .wins: return "Wins"
        case .pending: return "Pending"
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        CustomCard(padding: Theme.Spacing.sm) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Text(value)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary)
                
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: HypeSession
    
    private var mascot: Mascot {
        Mascot(rawValue: session.mascotUsed) ?? .sparky
    }
    
    private var outcomeEmoji: String {
        switch session.outcome {
        case "win": return "✅"
        case "meh": return "😐"
        case "tough": return "😤"
        default: return "⏳"
        }
    }
    
    var body: some View {
        CustomCard(padding: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    // Mascot
                    Text(mascot.emoji)
                        .font(.title2)
                        .padding(8)
                        .background(mascot.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.scenario)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        
                        Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Outcome
                    Text(outcomeEmoji)
                        .font(.title2)
                }
                
                // User input preview
                if !session.userInput.isEmpty {
                    Text(session.userInput)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(2)
                        .padding(.leading, 4)
                        .padding(.trailing, 4)
                }
                
                // Outcome notes
                if let notes = session.outcomeNotes, !notes.isEmpty {
                    Text(notes)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                        .italic()
                        .padding(.top, 4)
                }
            }
        }
    }
}

#Preview {
    HistoryView(subscriptionManager: SubscriptionManager())
        .modelContainer(for: [HypeSession.self, UserProfile.self], inMemory: true)
}
