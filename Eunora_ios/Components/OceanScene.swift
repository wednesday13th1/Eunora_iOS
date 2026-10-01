import SwiftUI

struct OceanScene: View {
    var progress: Double
    var weather: SeaWeather?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var moving = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: skyColors, startPoint: .top, endPoint: .bottom)
                Circle().fill(EunoiaColor.cream.opacity(0.9)).frame(width: 48).blur(radius: 1).offset(x: proxy.size.width * 0.3, y: -72)
                HStack(spacing: -13) { Circle().frame(width: 36); Circle().frame(width: 52); Circle().frame(width: 32) }
                    .foregroundStyle(.white.opacity(0.72)).offset(x: moving ? proxy.size.width * 0.46 : -proxy.size.width * 0.46, y: -54)
                    .animation(reduceMotion ? nil : .linear(duration: 24).repeatForever(autoreverses: true), value: moving)
                Image(systemName: "mountain.2.fill").font(.system(size: 62)).foregroundStyle(EunoiaColor.deepOcean.opacity(0.28)).offset(x: proxy.size.width * 0.32, y: 20)
                Capsule().fill(EunoiaColor.dustyBlue).frame(width: 470, height: 94).offset(x: moving ? -12 : 8, y: 86)
                Capsule().fill(EunoiaColor.deepOcean.opacity(0.76)).frame(width: 470, height: 76).offset(x: moving ? 10 : -8, y: 108)
                Image(systemName: "sailboat.fill").font(.system(size: 62)).foregroundStyle(EunoiaColor.cream, EunoiaColor.gold)
                    .shadow(color: EunoiaColor.ink.opacity(0.18), radius: 4, y: 3)
                    .offset(x: -proxy.size.width * 0.3 + CGFloat(progress) * proxy.size.width * 0.57, y: moving && !reduceMotion ? 42 : 47)
                    .animation(.spring(response: 0.8, dampingFraction: 0.72), value: progress)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: moving)
            }.clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .frame(height: 250).accessibilityElement(children: .ignore).accessibilityLabel("A small sailboat traveling across a calm sea")
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
