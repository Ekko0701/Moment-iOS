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

    // MARK: - Presets (Final-MVP — 화면별 3색 조합, 투명도 22~40%)

    public static func login() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbCoral, size: 220, x: -60, y: 60, opacity: 0.35),
            Orb(color: MomentColor.orbLavender, size: 200, x: 100, y: 500, opacity: 0.30),
            Orb(color: MomentColor.orbYellow, size: 140, x: 250, y: 300, opacity: 0.22),
        ])
    }

    public static func connect() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbYellow, size: 190, x: 220, y: 80, opacity: 0.40),
            Orb(color: MomentColor.orbBlue, size: 190, x: -50, y: 300, opacity: 0.35),
            Orb(color: MomentColor.orbLavender, size: 150, x: 150, y: 600, opacity: 0.25),
        ])
    }

    public static func home() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbCoral, size: 230, x: 200, y: -70, opacity: 0.35),
            Orb(color: MomentColor.orbYellow, size: 190, x: -50, y: 480, opacity: 0.32),
            Orb(color: MomentColor.orbLavender, size: 160, x: 240, y: 560, opacity: 0.28),
        ])
    }

    public static func feed() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbBlue, size: 190, x: 240, y: 40, opacity: 0.38),
            Orb(color: MomentColor.orbCoral, size: 190, x: -60, y: 500, opacity: 0.35),
            Orb(color: MomentColor.orbYellow, size: 140, x: 100, y: 690, opacity: 0.25),
        ])
    }

    public static func compose() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbLavender, size: 200, x: -50, y: 100, opacity: 0.38),
            Orb(color: MomentColor.orbYellow, size: 180, x: 250, y: 340, opacity: 0.38),
            Orb(color: MomentColor.orbBlue, size: 150, x: 60, y: 640, opacity: 0.25),
        ])
    }

    public static func settings() -> OrbBackground {
        OrbBackground([
            Orb(color: MomentColor.orbBlue, size: 180, x: 240, y: 60, opacity: 0.35),
            Orb(color: MomentColor.orbCoral, size: 190, x: -60, y: 440, opacity: 0.30),
            Orb(color: MomentColor.orbLavender, size: 150, x: 170, y: 680, opacity: 0.25),
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
