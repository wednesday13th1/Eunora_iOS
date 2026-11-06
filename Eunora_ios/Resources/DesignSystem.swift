import SwiftUI

enum EunoiaColor {
    static let background = Color(hex: 0xF5F0EA), secondaryBackground = Color(hex: 0xDFEAEB)
    static let deepOcean = Color(hex: 0x2C4A5C), oceanBlue = Color(hex: 0x3A5A72)
    static let softSeaBlue = Color(hex: 0x9AB3CA), mistBlue = Color(hex: 0xC6DDED)
    static let warmSand = Color(hex: 0xE0D8D0), lightSand = Color(hex: 0xF8F0E4)
    static let gold = Color(hex: 0xC49A42), coral = Color(hex: 0xC98279), leaf = Color(hex: 0x4A9A60)
    static let primaryText = Color(hex: 0x2C4A5C), secondaryText = Color(hex: 0x5A7A92), card = Color(hex: 0xF8F3EE)
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
    static func story(_ size: CGFloat, weight: Weight = .semibold) -> Font {
        .custom(weight == .regular ? "Fraunces-Regular" : "Fraunces-SemiBold", size: size, relativeTo: .title)
    }

    static func voyageBody(_ size: CGFloat = 16, relativeTo style: TextStyle = .body) -> Font {
        .custom("Nunito-Regular", size: size, relativeTo: style)
    }
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

struct EditorialHeading: View {
    let text: String
    var size: CGFloat = 32

    var body: some View {
        Text(text)
            .font(.story(size))
            .foregroundStyle(EunoiaColor.deepOcean)
    }
}

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

enum EunoiaLayout {
    static func horizontalPadding(for width: CGFloat) -> CGFloat {
        if width < 375 { return 16 }
        return width < 430 ? 20 : 24
    }

    static let readableWidth: CGFloat = 480
}

private struct ReadableContent: ViewModifier {
    @State private var width: CGFloat = 375

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: EunoiaLayout.readableWidth)
            .padding(.horizontal, EunoiaLayout.horizontalPadding(for: width))
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { width = $0 }
    }
}

extension View {
    func eunoiaReadableContent() -> some View {
        modifier(ReadableContent())
    }
}
