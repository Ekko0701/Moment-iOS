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
                    .blur(radius: 55)
                    .position(x: orb.x + orb.size / 2, y: orb.y + orb.size / 2)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Presets (Design F - Warm Paper Theme)
    public static func home() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbCoral, size: 210, x: 140, y: 150, opacity: 0.5),
            Orb(color: MomentColor.orbYellow, size: 170, x: -40, y: 330, opacity: 0.5),
            Orb(color: MomentColor.orbBlue, size: 170, x: 230, y: 380, opacity: 0.42),
            Orb(color: MomentColor.orbLavender, size: 160, x: 90, y: 560, opacity: 0.42),
        ])
    }

    public static func login() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbCoral, size: 220, x: -60, y: 60, opacity: 0.35),
            Orb(color: MomentColor.orbBlue, size: 190, x: 240, y: 200, opacity: 0.4),
            Orb(color: MomentColor.orbLavender, size: 200, x: 100, y: 480, opacity: 0.3),
        ])
    }

    public static func feed() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbBlue, size: 190, x: 240, y: 60, opacity: 0.4),
            Orb(color: MomentColor.orbCoral, size: 190, x: -60, y: 260, opacity: 0.42),
            Orb(color: MomentColor.orbYellow, size: 180, x: 220, y: 500, opacity: 0.4),
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
