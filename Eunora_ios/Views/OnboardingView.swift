import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: EunoiaSpacing.lg) {
                Text("EUNORA")
                    .font(.caption.weight(.semibold))
                    .tracking(3)
                OceanScene(progress: 0.18, weather: .calm)
                Text("Welcome aboard.")
                    .font(.story(36))
                    .accessibilityAddTraits(.isHeader)
                Text("Recovery isn’t a race. It’s a voyage made of many small steps.")
                    .font(.voyageBody(19, relativeTo: .title3))
                    .multilineTextAlignment(.center)
                Button("Begin my voyage", action: onComplete)
                    .buttonStyle(PrimaryButtonStyle())
            }
            .foregroundStyle(EunoiaColor.deepOcean)
            .padding(.vertical, EunoiaSpacing.lg)
            .eunoiaReadableContent()
        }
        .background { StorybookBackground() }
    }
}
