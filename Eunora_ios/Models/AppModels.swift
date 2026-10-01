import Foundation
import SwiftData

@Model final class VoyageProfile {
    var destination: String
    var anchors: Int
    var distance: Double
    var selectedSailor: String
    init(destination: String = "Kyoto", anchors: Int = 0, distance: Double = 0.12, selectedSailor: String = "sailor") {
        self.destination = destination; self.anchors = anchors; self.distance = distance; self.selectedSailor = selectedSailor
    }
}

@Model final class DailyQuest {
    var title: String; var symbol: String; var dayKey: String; var isCompleted: Bool; var isSkipped: Bool
    init(title: String, symbol: String, dayKey: String, isCompleted: Bool = false, isSkipped: Bool = false) {
        self.title = title; self.symbol = symbol; self.dayKey = dayKey; self.isCompleted = isCompleted; self.isSkipped = isSkipped
    }
}

@Model final class CheckIn {
    var dayKey: String; var weather: String; var createdAt: Date
    init(dayKey: String, weather: String, createdAt: Date = .now) { self.dayKey = dayKey; self.weather = weather; self.createdAt = createdAt }
}

@Model final class LogEntry {
    var createdAt: Date; var difficult: String; var helped: String; var proud: String
    init(createdAt: Date = .now, difficult: String = "", helped: String = "", proud: String = "") {
        self.createdAt = createdAt; self.difficult = difficult; self.helped = helped; self.proud = proud
    }
}

enum SeaWeather: String, CaseIterable, Identifiable {
    case calm = "Calm", cloudy = "A little cloudy", heavy = "Heavy", stormy = "Stormy", unsure = "I don’t know"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .calm: "sun.max.fill"; case .cloudy: "cloud.sun.fill"; case .heavy: "cloud.rain.fill"; case .stormy: "water.waves"; case .unsure: "moon.stars.fill" }
    }
}

extension Date { var eunoiaDayKey: String { formatted(.iso8601.year().month().day()) } }
