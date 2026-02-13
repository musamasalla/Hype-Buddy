//
//  FloatingParticlesView.swift
//  Hype Buddy
//
//  Ambient floating emoji particles for background energy
//

import SwiftUI

struct FloatingParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let startX: CGFloat
    let startY: CGFloat
    let size: CGFloat
    let duration: Double
    let delay: Double
}

struct FloatingParticlesView: View {
    let emojis: [String]
    let count: Int
    
    @State private var animate = false
    
    init(emojis: [String] = ["🔥", "✨", "⭐️", "💪", "🚀"], count: Int = 12) {
        self.emojis = emojis
        self.count = count
    }
    
    private var particles: [FloatingParticle] {
        (0..<count).map { i in
            FloatingParticle(
                emoji: emojis[i % emojis.count],
                startX: CGFloat.random(in: 0...1),
                startY: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 14...24),
                duration: Double.random(in: 4...8),
                delay: Double.random(in: 0...3)
            )
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { particle in
                Text(particle.emoji)
                    .font(.system(size: particle.size))
                    .position(
                        x: particle.startX * geo.size.width,
                        y: particle.startY * geo.size.height
                    )
                    .opacity(animate ? 0.15 : 0.05)
                    .offset(y: animate ? -30 : 30)
                    .animation(
                        .easeInOut(duration: particle.duration)
                        .repeatForever(autoreverses: true)
                        .delay(particle.delay),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
        .allowsHitTesting(false)
    }
}
