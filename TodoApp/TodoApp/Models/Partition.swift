import Foundation
import SwiftUI

struct Partition: Identifiable, Equatable, Codable {
    let id: String
    var name: String
    var color: PartitionColor
    var height: CGFloat

    init(id: String = UUID().uuidString, name: String, color: PartitionColor, height: CGFloat = 200) {
        self.id = id
        self.name = name
        self.color = color
        self.height = height
    }
}

enum PartitionColor: String, CaseIterable, Equatable, Codable {
    case blue, green, red, yellow, purple, orange

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .blue:   return .blue
        case .green:  return .green
        case .red:    return .red
        case .yellow: return .yellow
        case .purple: return .purple
        case .orange: return .orange
        }
    }

    var emoji: String {
        switch self {
        case .blue: return "🫧"
        case .green: return "🥝"
        case .red: return "🌶️"
        case .yellow: return "🌼"
        case .purple: return "🔮"
        case .orange: return "🍊"
        }
    }
}
