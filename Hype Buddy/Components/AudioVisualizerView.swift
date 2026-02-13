//
//  AudioVisualizerView.swift
//  Hype Buddy
//
//  Concentric ring audio visualizer for VoiceChatView
//

import SwiftUI

struct AudioVisualizerView: View {
    let color: Color
    let isActive: Bool
    let ringCount: Int
    
    @State private var scales: [CGFloat]
    @State private var opacities: [Double]
    
    init(color: Color, isActive: Bool, ringCount: Int = 3) {
        self.color = color
        self.isActive = isActive
        self.ringCount = ringCount
        _scales = State(initialValue: Array(repeating: 1.0, count: ringCount))
        _opacities = State(initialValue: Array(repeating: 0.0, count: ringCount))
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<ringCount, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(opacities[index]), lineWidth: 2)
                    .frame(
                        width: 220 + CGFloat(index) * 40,
                        height: 220 + CGFloat(index) * 40
                    )
                    .scaleEffect(scales[index])
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
        .onAppear {
            if isActive { startAnimating() }
        }
    }
    
    private func startAnimating() {
        for i in 0..<ringCount {
            let delay = Double(i) * 0.3
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) {
                scales[i] = 1.15 + CGFloat(i) * 0.05
                opacities[i] = 0.4 - Double(i) * 0.1
            }
        }
    }
    
    private func stopAnimating() {
        withAnimation(.easeOut(duration: 0.5)) {
            for i in 0..<ringCount {
                scales[i] = 1.0
                opacities[i] = 0.0
            }
        }
    }
}

// MARK: - Waveform Dots (Listening indicator)

struct WaveformDotsView: View {
    let color: Color
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animating ? CGFloat.random(in: 0.5...1.5) : 1.0)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}
