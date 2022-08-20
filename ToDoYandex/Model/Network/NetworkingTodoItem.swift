import Foundation

struct TodoItemNetworking: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case priority = "importance"
        case deadline
        case isCompleted = "done"
        case dateOfCreation = "created_at"
        case dateOfChange = "changed_at"
        case lastUpdateBy = "last_updated_by"
    }

    enum Importance: String {
        case basic
        case important
        case low
    }

    let id: String
    let text: String
    let priority: String
    let deadline: Int64?
    let isCompleted: Bool
    let dateOfCreation: Int64
    let dateOfChange: Int64?
    let lastUpdateBy: String

    init(item: TodoItem) {
        self.id = item.id
        self.text = item.text
        switch item.priority {
        case .common:
            self.priority = Importance.basic.rawValue
        case .important:
            self.priority = Importance.important.rawValue
        case .unimportant:
            self.priority = Importance.low.rawValue
        }
        self.isCompleted = item.isCompleted
        self.dateOfCreation = Int64(item.dateOfCreation.timeIntervalSince1970)
        self.lastUpdateBy = "iPhone11"

        if let deadline = item.deadline {
            self.deadline = Int64(deadline.timeIntervalSince1970)
        } else {
            self.deadline = nil
        }

        if let dateOfChange = item.dateOfChange {
            self.dateOfChange = Int64(dateOfChange.timeIntervalSince1970)
        } else {
            self.dateOfChange = nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        priority = try container.decode(String.self, forKey: .priority)
        deadline = try? container.decode(Int64.self, forKey: .deadline)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        dateOfCreation = try container.decode(Int64.self, forKey: .dateOfCreation)
        dateOfChange = try? container.decode(Int64.self, forKey: .dateOfChange)
        lastUpdateBy = try container.decode(String.self, forKey: .lastUpdateBy)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(priority, forKey: .priority)
        try container.encode(deadline, forKey: .deadline)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(dateOfCreation, forKey: .dateOfCreation)
        try container.encode(dateOfChange, forKey: .dateOfChange)
        try container.encode(lastUpdateBy, forKey: .lastUpdateBy)
    }
}
