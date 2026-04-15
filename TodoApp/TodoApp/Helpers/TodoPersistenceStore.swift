import Foundation

struct TodoPersistedState: Codable, Equatable {
    var partitions: [Partition]
    var tasks: [TodoTask]
    var tagHistoryByPartition: [String: [String]]
}

struct TodoPersistenceStore {
    static let bundleIdentifier = "com.todoapp.TodoApp"
    static let fileName = "todo-data.json"

    let fileURL: URL
    private let fileManager: FileManager

    init(
        fileURL: URL = TodoPersistenceStore.defaultFileURL(),
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    func loadState() throws -> TodoPersistedState? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TodoPersistedState.self, from: data)
    }

    func saveState(_ state: TodoPersistedState) throws {
        try ensureParentDirectoryExists()

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
    }

    func deleteState() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    private func ensureParentDirectoryExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    static func defaultFileURL(fileManager: FileManager = .default) -> URL {
        let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return applicationSupportURL
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent(fileName, isDirectory: false)
    }
}
