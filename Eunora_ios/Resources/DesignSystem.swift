import SwiftUI

enum EunoiaColor {
    static let background = Color(hex: 0xF7F2E6), secondaryBackground = Color(hex: 0xEEF3EE)
    static let deepOcean = Color(hex: 0x264E5B), oceanBlue = Color(hex: 0x35677A)
    static let softSeaBlue = Color(hex: 0xAFCFE0), mistBlue = Color(hex: 0xDDEBEF)
    static let warmSand = Color(hex: 0xD8C2A6), lightSand = Color(hex: 0xEFE1C8)
    static let gold = Color(hex: 0xCDA64D), coral = Color(hex: 0xC98279), leaf = Color(hex: 0x4A9A60)
    static let primaryText = Color(hex: 0x233F46), secondaryText = Color(hex: 0x6F7475), card = Color(hex: 0xFFFDF8)
    static let dustyBlue = softSeaBlue, sky = mistBlue, foam = secondaryBackground, sand = warmSand
    static let cream = background, ink = primaryText, parchment = lightSand, wood = Color(hex: 0x785533)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: alpha)
    }
}

enum EunoiaSpacing { static let xxs: CGFloat = 4; static let xs: CGFloat = 8; static let sm: CGFloat = 12; static let md: CGFloat = 16; static let lg: CGFloat = 24; static let xl: CGFloat = 32; static let xxl: CGFloat = 40; static let hero: CGFloat = 48; static let screen: CGFloat = 24 }
enum EunoiaRadius { static let control: CGFloat = 12; static let input: CGFloat = 16; static let card: CGFloat = 20; static let largeCard: CGFloat = 24; static let hero: CGFloat = 30 }
enum EunoiaMotion { static let micro = Animation.easeOut(duration: 0.18); static let normal = Animation.easeInOut(duration: 0.28); static let slow = Animation.easeInOut(duration: 0.6); static let collectible = Animation.spring(response: 0.4, dampingFraction: 0.72) }

extension Font {
    static func story(_ size: CGFloat, weight: Weight = .semibold) -> Font { .system(size: size, weight: weight, design: .serif) }
    static let eunoiaScreenTitle = Font.system(size: 42, weight: .bold, design: .rounded)
    static let eunoiaSectionTitle = Font.system(size: 28, weight: .bold, design: .rounded)
}

struct StorybookBackground: View {
    var body: some View { LinearGradient(colors: [EunoiaColor.background, EunoiaColor.mistBlue.opacity(0.42)], startPoint: .top, endPoint: .bottom).ignoresSafeArea() }
}

struct EunoiaCard<Content: View>: View {
    var radius: CGFloat = EunoiaRadius.card; var tint: Color = EunoiaColor.card; var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View { content.padding(padding).background(tint, in: RoundedRectangle(cornerRadius: radius, style: .continuous)).overlay(RoundedRectangle(cornerRadius: radius).stroke(EunoiaColor.deepOcean.opacity(0.08))).shadow(color: .black.opacity(0.04), radius: 8, y: 3) }
}
typealias SoftCard = EunoiaCard

struct EditorialHeading: View { let text: String; var size: CGFloat = 32; var body: some View { Text(text).font(.story(size)).foregroundStyle(EunoiaColor.deepOcean) } }

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 18, weight: .semibold)).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 60)
            .background(EunoiaColor.deepOcean.opacity(configuration.isPressed ? 0.84 : 1), in: Capsule()).scaleEffect(configuration.isPressed ? 0.97 : 1).animation(EunoiaMotion.micro, value: configuration.isPressed)
    }
}

struct ParchmentCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.padding(20).background(EunoiaColor.lightSand, in: RoundedRectangle(cornerRadius: 23, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 23).stroke(EunoiaColor.warmSand.opacity(0.5))).shadow(color: .black.opacity(0.04), radius: 8, y: 3) }
}

struct EunoiaBackButton: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View { Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)).frame(width: 44, height: 44).foregroundStyle(EunoiaColor.deepOcean).background(EunoiaColor.card, in: Circle()).overlay(Circle().stroke(EunoiaColor.deepOcean.opacity(0.12))) }.accessibilityLabel("Back") }
}
