import SwiftUI

/// Physics-based confetti drawn with Canvas: two cannons fire from the bottom
/// corners, then a gentle shower falls from the top.
struct ConfettiView: View {
    var colors: [Color] = [.pink, .orange, .yellow, .mint, .cyan, .purple, .indigo]
    /// Change this value to fire again.
    var trigger: Int = 0

    @State private var particles: [Particle] = []
    @State private var startDate = Date.now

    private static let gravity: Double = 1100
    private static let lifetime: Double = 4.5

    struct Particle {
        var origin: CGPoint      // unit coordinates
        var velocity: CGVector   // points per second
        var delay: Double
        var size: CGFloat
        var rotation: Double
        var spin: Double
        var flutter: Double
        var color: Color
        var isCircle: Bool
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(startDate)
                guard elapsed < Self.lifetime + 1.5 else { return }

                for particle in particles {
                    let t = elapsed - particle.delay
                    guard t > 0 else { continue }

                    // Air drag keeps it floaty.
                    let drag = 1 / (1 + t * 0.9)
                    let x = particle.origin.x * size.width + particle.velocity.dx * t * drag
                    let y = particle.origin.y * size.height + particle.velocity.dy * t * drag + 0.5 * Self.gravity * t * t * 0.55
                    let fade = max(0, min(1, (Self.lifetime - t) / 1.0))
                    guard fade > 0, y < size.height + 30 else { continue }

                    var ctx = context
                    ctx.opacity = fade
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(particle.rotation + particle.spin * t))
                    ctx.scaleBy(x: cos(t * particle.flutter), y: 1)

                    let rect = CGRect(x: -particle.size / 2, y: -particle.size * 0.3, width: particle.size, height: particle.size * 0.6)
                    let path = particle.isCircle
                        ? Path(ellipseIn: CGRect(x: -particle.size * 0.3, y: -particle.size * 0.3, width: particle.size * 0.6, height: particle.size * 0.6))
                        : Path(roundedRect: rect, cornerRadius: 1.5)
                    ctx.fill(path, with: .color(particle.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear(perform: fire)
        .onChange(of: trigger) { _, _ in fire() }
    }

    private func fire() {
        var result: [Particle] = []

        func cannon(fromX x: CGFloat, direction: Double) {
            for _ in 0..<70 {
                let speed = Double.random(in: 650...1250)
                let angle = Double.random(in: 55...82) * .pi / 180
                result.append(Particle(
                    origin: CGPoint(x: x, y: 1.02),
                    velocity: CGVector(dx: cos(angle) * speed * direction, dy: -sin(angle) * speed),
                    delay: Double.random(in: 0...0.15),
                    size: .random(in: 7...13),
                    rotation: .random(in: 0...(2 * .pi)),
                    spin: .random(in: -9...9),
                    flutter: .random(in: 4...12),
                    color: colors.randomElement() ?? .pink,
                    isCircle: Double.random(in: 0...1) < 0.25
                ))
            }
        }

        cannon(fromX: 0.02, direction: 1)
        cannon(fromX: 0.98, direction: -1)

        for _ in 0..<60 {
            result.append(Particle(
                origin: CGPoint(x: .random(in: 0...1), y: -0.05),
                velocity: CGVector(dx: .random(in: -60...60), dy: .random(in: 40...160)),
                delay: Double.random(in: 0.5...1.8),
                size: .random(in: 6...11),
                rotation: .random(in: 0...(2 * .pi)),
                spin: .random(in: -6...6),
                flutter: .random(in: 3...9),
                color: colors.randomElement() ?? .yellow,
                isCircle: Double.random(in: 0...1) < 0.3
            ))
        }

        particles = result
        startDate = .now
    }
}
