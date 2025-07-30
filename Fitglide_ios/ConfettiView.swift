//
//  ConfettiView.swift
//  Fitglide_ios
//
//  Created by Sandip Tiwari on 21/07/25.
//

import Foundation
import SwiftUI

struct ConfettiView: View {
    @Binding var trigger: Int
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var rotation: Angle
        var rotationSpeed: Double
        var color: Color
        var scale: CGFloat
        var opacity: Double
        var shape: ShapeType // Added to support multiple shapes
        
        enum ShapeType {
            case circle
            case rectangle
            case triangle
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Group {
                        switch particle.shape {
                        case .circle:
                            Circle()
                                .fill(particle.color)
                                .frame(width: 12 * particle.scale, height: 12 * particle.scale)
                        case .rectangle:
                            RoundedRectangle(cornerRadius: 4)
                                .fill(particle.color)
                                .frame(width: 10 * particle.scale, height: 10 * particle.scale)
                        case .triangle:
                            Triangle()
                                .fill(particle.color)
                                .frame(width: 10 * particle.scale, height: 10 * particle.scale)
                        }
                    }
                    .rotationEffect(particle.rotation)
                    .opacity(particle.opacity)
                    .position(particle.position)
                }
            }
            .zIndex(10) // Ensure particles are on top
            .onChange(of: trigger) {
                generatePopperParticles(in: geometry)
                withAnimation(.linear(duration: 1.2)) {
                    particles = particles.map { particle in
                        var p = particle
                        p.position.x += particle.velocity.dx
                        p.position.y += particle.velocity.dy
                        p.rotation += Angle(degrees: particle.rotationSpeed)
                        p.opacity = max(0, particle.opacity - 0.04)
                        return p
                    }
                    particles = particles.filter { $0.opacity > 0 }
                }
            }
        }
    }
    
    private func generatePopperParticles(in geometry: GeometryProxy) {
        let colors = [
            FitGlideTheme.colors(for: .light).primary,
            FitGlideTheme.colors(for: .light).secondary,
            FitGlideTheme.colors(for: .light).tertiary,
            FitGlideTheme.colors(for: .light).quaternary
        ]
        
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        
        particles = (0..<60).map { _ in // Increased particle count
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 15...25) // Higher velocity for burst
            let velocity = CGVector(
                dx: cos(angle) * speed,
                dy: sin(angle) * speed
            )
            
            return Particle(
                position: center,
                velocity: velocity,
                rotation: Angle(degrees: CGFloat.random(in: 0...360)),
                rotationSpeed: CGFloat.random(in: -15...15),
                color: colors.randomElement() ?? .blue,
                scale: CGFloat.random(in: 0.8...2.0),
                opacity: 1.0,
                shape: [.circle, .rectangle, .triangle].randomElement() ?? .circle
            )
        }
    }
}

// Custom Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
