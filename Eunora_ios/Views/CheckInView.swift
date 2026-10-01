import SwiftUI
import SwiftData

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var selected: SeaWeather? = .calm
    @State private var page = 0

    var body: some View {
        NavigationStack {
            ZStack {
                StorybookBackground()
                VStack(spacing: 22) {
                    Text("How does the sea feel today?").font(.story(29)).multilineTextAlignment(.center).foregroundStyle(EunoiaColor.ink)
                    Text("There is no right answer, and nothing here is scored.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                    TabView(selection: $page) {
                        ForEach(Array(SeaWeather.allCases.enumerated()), id: \.element.id) { index, weather in
                            VStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 30).fill(LinearGradient(colors: weatherColors(weather), startPoint: .top, endPoint: .bottom))
                                    Image(systemName: weather.symbol).font(.system(size: 84)).foregroundStyle(.white, EunoiaColor.gold)
                                    WaveShape(phase: CGFloat(index) * 0.2).fill(EunoiaColor.deepOcean.opacity(0.62)).frame(height: 80).offset(y: 75)
                                }.frame(height: 245).clipShape(RoundedRectangle(cornerRadius: 30))
                                Text(weather.rawValue).font(.story(24)).foregroundStyle(EunoiaColor.ink)
                            }.tag(index).padding(.horizontal, 8)
                        }
                    }.tabViewStyle(.page(indexDisplayMode: .always)).frame(height: 330)
                        .onChange(of: page) { _, newValue in selected = SeaWeather.allCases[newValue]; UISelectionFeedbackGenerator().selectionChanged() }
                    Text("Swipe the little sea to find yours").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("This feels like my sea") { let weather = selected ?? SeaWeather.allCases[page]; context.insert(CheckIn(dayKey: Date.now.eunoiaDayKey, weather: weather.rawValue)); UINotificationFeedbackGenerator().notificationOccurred(.success); dismiss() }
                        .buttonStyle(PrimaryButtonStyle()).disabled(selected == nil).opacity(selected == nil ? 0.5 : 1)
                }.padding(24)
            }.toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Not now") { dismiss() } } }
        }.presentationDetents([.large])
    }

    private func weatherColors(_ weather: SeaWeather) -> [Color] {
        switch weather {
        case .calm: [EunoiaColor.sky, EunoiaColor.foam]
        case .cloudy: [EunoiaColor.dustyBlue, EunoiaColor.sky]
        case .heavy: [.gray.opacity(0.75), EunoiaColor.dustyBlue]
        case .stormy: [EunoiaColor.deepOcean.opacity(0.9), EunoiaColor.dustyBlue]
        case .unsure: [Color.indigo.opacity(0.62), EunoiaColor.sky]
        }
    }
}
