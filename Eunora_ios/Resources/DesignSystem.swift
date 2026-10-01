import SwiftUI

enum EunoiaColor {
    static let dustyBlue = Color(red: 0.60, green: 0.70, blue: 0.79)
    static let sky = Color(red: 0.78, green: 0.87, blue: 0.93)
    static let foam = Color(red: 0.87, green: 0.92, blue: 0.92)
    static let sand = Color(red: 0.88, green: 0.85, blue: 0.82)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let gold = Color(red: 0.76, green: 0.61, blue: 0.31)
    static let deepOcean = Color(red: 0.18, green: 0.35, blue: 0.43)
    static let ink = Color(red: 0.16, green: 0.25, blue: 0.28)
}

struct StorybookBackground: View {
    var body: some View { LinearGradient(colors: [EunoiaColor.cream, EunoiaColor.foam.opacity(0.72)], startPoint: .top, endPoint: .bottom).ignoresSafeArea() }
}

struct SoftCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(18).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.7), lineWidth: 1))
            .shadow(color: EunoiaColor.deepOcean.opacity(0.09), radius: 16, y: 8)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 54)
            .background(EunoiaColor.deepOcean.opacity(configuration.isPressed ? 0.78 : 1), in: Capsule()).scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
