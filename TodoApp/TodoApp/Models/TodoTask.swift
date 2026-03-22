import Foundation

struct TodoTask: Identifiable, Equatable {
    let id: String
    var partitionId: String
    var name: String
    var isCompleted: Bool
    var isStarred: Bool
    var dueDate: Date?
    var createdAt: Date
    var completedAt: Date?

    init(
        id: String = UUID().uuidString,
        partitionId: String,
        name: String,
        isCompleted: Bool = false,
        isStarred: Bool = false,
        dueDate: Date? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.partitionId = partitionId
        self.name = name
        self.isCompleted = isCompleted
        self.isStarred = isStarred
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}
