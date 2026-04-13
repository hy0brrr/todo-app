import Foundation

enum TaskTextSegment: Equatable {
    case text(String)
    case tag(String)
}

struct ParsedTaskText: Equatable {
    let name: String
    let tags: [String]
    let markupText: String
}

struct TodoTask: Identifiable, Equatable {
    let id: String
    var partitionId: String
    var name: String
    var parentTaskId: String?
    var tags: [String]
    var markupText: String
    var isCompleted: Bool
    var isStarred: Bool
    var starredAt: Date?
    var unstarredAt: Date?
    var dueDate: Date?
    var createdAt: Date
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        partitionId: String,
        name: String,
        parentTaskId: String? = nil,
        tags: [String] = [],
        markupText: String? = nil,
        isCompleted: Bool = false,
        isStarred: Bool = false,
        starredAt: Date? = nil,
        unstarredAt: Date? = nil,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.partitionId = partitionId
        self.name = name
        self.parentTaskId = parentTaskId
        self.tags = Self.normalizeTags(tags)
        self.markupText = markupText?.trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty ?? Self.composeMarkupText(name: name, tags: self.tags)
        self.isCompleted = isCompleted
        self.isStarred = isStarred
        self.starredAt = isStarred ? (starredAt ?? createdAt) : nil
        self.unstarredAt = isStarred ? nil : (unstarredAt ?? createdAt)
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    var isRootTask: Bool {
        parentTaskId == nil
    }

    var displayText: String {
        markupText
    }

    var displaySegments: [TaskTextSegment] {
        Self.parseDisplaySegments(from: markupText)
    }

    var renderSegments: [TaskTextSegment] {
        Self.normalizeRenderSegments(displaySegments)
    }

    static func parseDisplayText(_ text: String) -> ParsedTaskText {
        let pattern = #"\[([^\[\]]+)\]"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex?.matches(in: text, range: fullRange) ?? []

        let tags = matches.compactMap { match -> String? in
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: text) else {
                return nil
            }

            let value = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }

        let strippedName = matches.reversed().reduce(text) { partialResult, match in
            guard let range = Range(match.range, in: partialResult) else {
                return partialResult
            }
            return partialResult.replacingCharacters(in: range, with: " ")
        }

        let normalizedName = strippedName
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedTags = normalizeTags(tags)

        return ParsedTaskText(
            name: normalizedName,
            tags: normalizedTags,
            markupText: composeMarkupText(from: parseDisplaySegments(from: text), fallbackName: normalizedName, normalizedTags: normalizedTags)
        )
    }

    static func parseDisplaySegments(from text: String) -> [TaskTextSegment] {
        let pattern = #"\[([^\[\]]+)\]"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex?.matches(in: text, range: fullRange) ?? []

        var segments: [TaskTextSegment] = []
        var currentIndex = text.startIndex

        for match in matches {
            guard let fullMatchRange = Range(match.range, in: text),
                  let tagRange = Range(match.range(at: 1), in: text) else {
                continue
            }

            if currentIndex < fullMatchRange.lowerBound {
                let prefix = String(text[currentIndex..<fullMatchRange.lowerBound])
                if !prefix.isEmpty {
                    segments.append(.text(prefix))
                }
            }

            let tagValue = String(text[tagRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !tagValue.isEmpty {
                segments.append(.tag(tagValue))
            }

            currentIndex = fullMatchRange.upperBound
        }

        if currentIndex < text.endIndex {
            let suffix = String(text[currentIndex..<text.endIndex])
            if !suffix.isEmpty {
                segments.append(.text(suffix))
            }
        }

        return segments
    }

    static func normalizeTags(_ tags: [String]) -> [String] {
        return tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func normalizeRenderSegments(_ segments: [TaskTextSegment]) -> [TaskTextSegment] {
        segments.enumerated().compactMap { index, segment in
            switch segment {
            case .tag:
                return segment
            case .text(let text):
                let previous = index > 0 ? segments[index - 1] : nil
                let next = index < segments.count - 1 ? segments[index + 1] : nil
                var value = text

                if previous?.isTag == true {
                    value = value.replacingOccurrences(of: #"^\s+"#, with: "", options: .regularExpression)
                }

                if next?.isTag == true {
                    value = value.replacingOccurrences(of: #"\s+$"#, with: "", options: .regularExpression)
                }

                return value.isEmpty ? nil : .text(value)
            }
        }
    }

    private static func composeMarkupText(name: String, tags: [String]) -> String {
        if tags.isEmpty {
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ([name.trimmingCharacters(in: .whitespacesAndNewlines)] + tags.map { "[\($0)]" })
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func composeMarkupText(
        from segments: [TaskTextSegment],
        fallbackName: String,
        normalizedTags: [String]
    ) -> String {
        var remainingTags = normalizedTags

        let pieces = segments.compactMap { segment -> String? in
            switch segment {
            case .text(let text):
                let cleaned = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            case .tag(let tag):
                guard let index = remainingTags.firstIndex(of: tag) else { return nil }
                let value = remainingTags.remove(at: index)
                return "[\(value)]"
            }
        }

        let composed = pieces.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if composed.isEmpty {
            return composeMarkupText(name: fallbackName, tags: normalizedTags)
        }

        if remainingTags.isEmpty {
            return composed
        }

        return ([composed] + remainingTags.map { "[\($0)]" }).joined(separator: " ")
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension TaskTextSegment {
    var isTag: Bool {
        if case .tag = self { return true }
        return false
    }
}
