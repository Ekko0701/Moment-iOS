import SwiftUI

public struct Orb: Sendable {
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
}

public struct OrbBackground: View {
    let orbs: [Orb]

    public init(_ orbs: [Orb]) {
        self.orbs = orbs
    }

    public var body: some View {
        ZStack {
            ForEach(Array(orbs.enumerated()), id: \.offset) { _, orb in
                Circle()
                    .fill(orb.color.opacity(orb.opacity))
                    .frame(width: orb.size, height: orb.size)
                    .blur(radius: 60)
                    .position(x: orb.x + orb.size / 2, y: orb.y + orb.size / 2)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Presets
    public static func home() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbBlue, size: 220, x: 230 - 110, y: -40, opacity: 0.40),
            Orb(color: MomentColor.orbCoral, size: 200, x: 40, y: 430, opacity: 0.30),
            Orb(color: MomentColor.orbLavender, size: 180, x: 220, y: 520, opacity: 0.32),
            Orb(color: MomentColor.orbYellow, size: 140, x: 110, y: 630, opacity: 0.25),
        ])
    }

    public static func login() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbCoral, size: 220, x: -60, y: 60, opacity: 0.28),
            Orb(color: MomentColor.orbBlue, size: 190, x: 240, y: 200, opacity: 0.35),
            Orb(color: MomentColor.orbLavender, size: 200, x: 100, y: 480, opacity: 0.25),
        ])
    }

    public static func feed() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbBlue, size: 180, x: 260, y: 20, opacity: 0.30),
            Orb(color: MomentColor.orbCoral, size: 200, x: -70, y: 560, opacity: 0.22),
        ])
    }
}

#Preview {
    ZStack {
        MomentColor.canvas.ignoresSafeArea()
        OrbBackground.home().ignoresSafeArea()
        VStack {
            Text("Home Preview").font(.title)
            Spacer()
        }
        .padding()
    }
}
