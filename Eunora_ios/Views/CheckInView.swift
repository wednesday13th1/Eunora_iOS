import SwiftUI
import SwiftData

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var selected: SeaWeather?

    var body: some View {
        NavigationStack {
            ZStack {
                StorybookBackground()
                VStack(spacing: 22) {
                    Image(systemName: selected?.symbol ?? "cloud.sun.fill").font(.system(size: 72)).foregroundStyle(EunoiaColor.dustyBlue, EunoiaColor.gold).contentTransition(.symbolEffect(.replace))
                    Text("How does the sea feel today?").font(.title.bold()).multilineTextAlignment(.center).foregroundStyle(EunoiaColor.ink)
                    Text("There is no right answer, and nothing here is scored.").multilineTextAlignment(.center).foregroundStyle(.secondary)
                    VStack(spacing: 10) {
                        ForEach(SeaWeather.allCases) { weather in
                            Button { selected = weather } label: {
                                HStack { Image(systemName: weather.symbol).frame(width: 30); Text(weather.rawValue); Spacer(); if selected == weather { Image(systemName: "checkmark.circle.fill") } }
                                    .padding().frame(minHeight: 54).background(selected == weather ? EunoiaColor.sky : .white.opacity(0.6), in: RoundedRectangle(cornerRadius: 18))
                            }.foregroundStyle(EunoiaColor.deepOcean)
                        }
                    }
                    Spacer()
                    Button("Save check-in") { if let selected { context.insert(CheckIn(dayKey: Date.now.eunoiaDayKey, weather: selected.rawValue)); dismiss() } }
                        .buttonStyle(PrimaryButtonStyle()).disabled(selected == nil).opacity(selected == nil ? 0.5 : 1)
                }.padding(24)
            }.toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Not now") { dismiss() } } }
        }.presentationDetents([.large])
    }
}
