import Foundation

enum DateHelpers {
    static func daysFromToday(_ date: Date?) -> Int? {
        guard let date else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let dueDay = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: today, to: dueDay).day
    }

    static func isDueToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let dueDay = Calendar.current.startOfDay(for: date)
        return dueDay == today
    }

    static func isOverdue(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let dueDay = Calendar.current.startOfDay(for: date)
        return dueDay <= today
    }

    static func formatDueDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let today = Calendar.current.startOfDay(for: Date())
        let dueDay = Calendar.current.startOfDay(for: date)
        let diffDays = Calendar.current.dateComponents([.day], from: today, to: dueDay).day ?? 0

        switch diffDays {
        case 0:  return "Due Today"
        case 1:  return "Due Tomorrow"
        case -1: return "Due Yesterday"
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "MMM d"
            return "Due \(formatter.string(from: date))"
        }
    }
}
