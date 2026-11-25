import Foundation

struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    var content: String
    let timestamp: Date
    var isFavorite: Bool = false

    init(content: String) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.isFavorite = false
    }

    init(id: UUID, content: String, timestamp: Date, isFavorite: Bool = false) {
        self.id = id
        self.content = content
        self.timestamp = timestamp
        self.isFavorite = isFavorite
    }

    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let singleLine = trimmed.replacingOccurrences(of: "\n", with: " ")
        if singleLine.count > 80 {
            return String(singleLine.prefix(80)) + "..."
        }
        return singleLine
    }

    var isMultiline: Bool {
        content.contains("\n")
    }
}
