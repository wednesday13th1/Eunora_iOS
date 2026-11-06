import SwiftUI

struct OceanScene: View {
    var progress: Double
    var weather: SeaWeather?
    var destination: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var moving = false
    @State private var boatBounce = false
    @State private var cloudWiggle = false
    @State private var ripplePoint: CGPoint?
    @State private var bottleLift: CGFloat = 0
    var onBottleTap: (() -> Void)? = nil

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: skyColors, startPoint: .top, endPoint: .bottom)
                Circle().fill(EunoiaColor.cream.opacity(0.9)).frame(width: 48).blur(radius: 1).offset(x: proxy.size.width * 0.3, y: -72)
                HStack(spacing: -13) { Circle().frame(width: 36); Circle().frame(width: 52); Circle().frame(width: 32) }
                    .foregroundStyle(.white.opacity(0.72)).offset(x: moving ? proxy.size.width * 0.46 : -proxy.size.width * 0.46, y: -54)
                    .rotationEffect(.degrees(cloudWiggle ? 4 : -2)).onTapGesture { withAnimation(.spring(response: 0.25, dampingFraction: 0.35)) { cloudWiggle.toggle() } }
                    .animation(reduceMotion ? nil : .linear(duration: 24).repeatForever(autoreverses: true), value: moving)
                ZStack(alignment: .bottom) {
                    Image(systemName: "mountain.2.fill").font(.system(size: 70)).foregroundStyle(EunoiaColor.deepOcean.opacity(0.32))
                    if let destination {
                        Text(destination.uppercased()).font(.caption2.bold()).tracking(1.2)
                            .foregroundStyle(EunoiaColor.deepOcean).offset(y: 15)
                    }
                }.offset(x: proxy.size.width * 0.31, y: 12)
                WaveShape(phase: moving ? 0.55 : 0).fill(EunoiaColor.mistBlue).frame(height: 112).offset(y: 78)
                    .animation(reduceMotion ? nil : .linear(duration: 5).repeatForever(autoreverses: true), value: moving)
                WaveShape(phase: moving ? -0.45 : 0.2).fill(EunoiaColor.softSeaBlue).frame(height: 102).offset(y: 96)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 4).repeatForever(autoreverses: true), value: moving)
                if onBottleTap != nil {
                    ZStack {
                        BottleGlyph().frame(width: 28, height: 60)
                        Image(systemName: "sparkle").font(.caption).foregroundStyle(EunoiaColor.gold)
                            .offset(x: 22, y: -28).opacity(moving ? 1 : 0.2).scaleEffect(moving ? 1.15 : 0.7)
                    }.rotationEffect(.degrees(moving ? 8 : -7))
                        .offset(x: proxy.size.width * 0.29, y: 55 - bottleLift).onTapGesture { onBottleTap?() }
                        .accessibilityLabel("A sparkling message bottle").accessibilityHint("Tap to pull it from the sea").accessibilityAddTraits(.isButton)
                }
                Image(systemName: "sailboat.fill").font(.system(size: min(72, proxy.size.width * 0.20))).foregroundStyle(EunoiaColor.cream, EunoiaColor.gold)
                    .shadow(color: EunoiaColor.ink.opacity(0.18), radius: 4, y: 3)
                    .rotationEffect(.degrees(boatBounce ? -2 : 1.5))
                    .offset(x: -proxy.size.width * 0.3 + CGFloat(progress) * proxy.size.width * 0.57, y: moving && !reduceMotion ? 42 : 48)
                    .onTapGesture { UIImpactFeedbackGenerator(style: .soft).impactOccurred(); withAnimation(.spring(response: 0.35, dampingFraction: 0.35)) { boatBounce.toggle() } }
                    .animation(reduceMotion ? nil : .spring(response: 0.8, dampingFraction: 0.72), value: progress)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: moving)
                WaveShape(phase: moving ? -0.7 : 0.2).fill(EunoiaColor.oceanBlue.opacity(0.9)).frame(height: 88).offset(y: 116)
                    .animation(reduceMotion ? nil : .linear(duration: 6.5).repeatForever(autoreverses: true), value: moving)
                if let ripplePoint {
                    Circle().stroke(.white.opacity(0.75), lineWidth: 2).frame(width: 54, height: 18).position(ripplePoint).transition(.scale(scale: 0.1).combined(with: .opacity))
                }
            }.clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .contentShape(Rectangle()).simultaneousGesture(SpatialTapGesture().onEnded { value in
                    guard !reduceMotion, value.location.y > proxy.size.height * 0.55 else { return }
                    ripplePoint = value.location
                    withAnimation(.easeOut(duration: 0.8)) { ripplePoint = nil }
                })
        }
        .frame(height: 280).accessibilityElement(children: .ignore).accessibilityLabel("A small sailboat traveling across a calm sea toward Kyoto")
        .onAppear { moving = true }
    }

    private var skyColors: [Color] {
        switch weather {
        case .heavy, .stormy: [Color(red: 0.66, green: 0.73, blue: 0.77), EunoiaColor.sky]
        case .unsure: [Color(red: 0.56, green: 0.64, blue: 0.73), EunoiaColor.dustyBlue]
        default: [EunoiaColor.sky, EunoiaColor.foam]
        }
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var animatableData: CGFloat { get { phase } set { phase = newValue } }
    func path(in rect: CGRect) -> Path {
        var p = Path(); p.move(to: CGPoint(x: 0, y: rect.height * 0.28))
        let wavelength = rect.width / 2.2
        for x in stride(from: CGFloat.zero, through: rect.width, by: 3) {
            let y = rect.height * 0.25 + sin((x / wavelength + phase) * .pi * 2) * 10
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: rect.width, y: rect.height)); p.addLine(to: CGPoint(x: 0, y: rect.height)); p.closeSubpath(); return p
    }
}

struct BottleGlyph: View {
    var tint: Color = Color(red: 0.33, green: 0.58, blue: 0.55)
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 9).fill(tint.opacity(0.78)).overlay(RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.7), lineWidth: 2)).padding(.top, 13)
            Capsule().fill(EunoiaColor.wood).frame(width: 12, height: 17)
            RoundedRectangle(cornerRadius: 2).fill(EunoiaColor.parchment).frame(width: 15, height: 26).rotationEffect(.degrees(-8)).offset(y: 23)
        }.shadow(color: EunoiaColor.deepOcean.opacity(0.25), radius: 4, y: 3)
    }
}
