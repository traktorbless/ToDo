import Foundation

struct TodoItemSQL: Codable {
    enum Importance: String {
        case basic
        case important
        case low
    }

    let id: String
    let text: String
    let isCompleted: Bool
    let priority: String
    let dateOfCreation: Date
    let deadline: Date?
    let dateOfChange: Date?

    init(_ item: TodoItem) {
        self.id = item.id
        self.text = item.text
        self.isCompleted = item.isCompleted
        self.deadline = item.deadline
        self.dateOfCreation = item.dateOfCreation
        self.dateOfChange = item.dateOfChange
        switch item.priority {
        case .common:
            self.priority = Importance.basic.rawValue
        case .important:
            self.priority = Importance.important.rawValue
        case .unimportant:
            self.priority = Importance.low.rawValue
        }
    }
}
