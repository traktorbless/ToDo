import Foundation
import SQLite

struct TodoItem: Identifiable {
    let id: String
    let text: String
    let priority: Priority
    let deadline: Date?
    let isCompleted: Bool
    let dateOfCreation: Date
    let dateOfChange: Date?

    init(id: String = UUID().uuidString,
         text: String,
         priority: Priority = .common,
         deadline: Date? = nil, isCompleted: Bool = false,
         dateOfCreation: Date = Date(),
         dateOfChange: Date? = nil) {
        self.id = id
        self.text = text
        self.priority = priority
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.dateOfCreation = dateOfCreation
        self.dateOfChange = dateOfChange
    }

    init (coreDataItem: TodoItemCoreData) {
        self.id = coreDataItem.unwrappedID
        self.text = coreDataItem.unwrappedText
        self.isCompleted = coreDataItem.isCompleted
        self.dateOfCreation = coreDataItem.unwrappedDateOfCreation
        switch coreDataItem.priority {
        case "low":
            self.priority = .unimportant
        case "important":
            self.priority = .important
        default:
            self.priority = .common
        }
        self.deadline = coreDataItem.deadline
        self.dateOfChange = coreDataItem.dateOfChange
    }

    init(networkItem: TodoItemNetworking) {
        self.id = networkItem.id
        self.text = networkItem.text
        self.isCompleted = networkItem.isCompleted
        self.dateOfCreation = Date(timeIntervalSince1970: Double(networkItem.dateOfCreation))

        switch networkItem.priority {
        case "low":
            self.priority = .unimportant
        case "important":
            self.priority = .important
        default:
            self.priority = .common
        }

        if let deadline = networkItem.deadline {
            self.deadline = Date(timeIntervalSince1970: Double(deadline))
        } else {
            self.deadline = nil
        }

        if let dateOfChange = networkItem.dateOfChange {
            self.dateOfChange = Date(timeIntervalSince1970: Double(dateOfChange))
        } else {
            self.dateOfChange = nil
        }
    }

    enum Priority: String {
        case important = "Важная"
        case unimportant = "Неважная"
        case common = "Обычная"
    }

    var asCompleted: TodoItem {
        TodoItem(
            id: id,
            text: text,
            priority: priority,
            deadline: deadline,
            isCompleted: !self.isCompleted,
            dateOfCreation: dateOfCreation,
            dateOfChange: Date()
        )
    }
}

// MARK: Парсинг JSON и его создание из структуры
extension TodoItem {
    enum JsonKeys: String {
        case id
        case text
        case priority
        case isCompleted
        case dateOfCreation
        case deadline
        case dateOfChange
    }

    static func parse(json: Any) -> TodoItem? {
        assert(!Thread.isMainThread)
        func stringToDate(from string: String?) -> Date? {
            guard let string = string else {
                return nil
            }

            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .short

            return dateFormatter.date(from: string)
        }

        guard let dictionary = json as? [String: Any] else { return nil }

        guard let id = dictionary[JsonKeys.id.rawValue] as? String,
              let text = dictionary[JsonKeys.text.rawValue] as? String,
              let isCompleted = dictionary[JsonKeys.isCompleted.rawValue] as? Bool,
              let stringDateOfCreation = dictionary[JsonKeys.dateOfCreation.rawValue] as? String else {
            return nil
        }

        let priority = (dictionary[JsonKeys.priority.rawValue] as? String).flatMap(Priority.init) ?? .common
        let stringDeadline = dictionary[JsonKeys.deadline.rawValue] as? String
        let stringDateOfChange = dictionary[JsonKeys.dateOfChange.rawValue] as? String

        if let dateOfCreation = stringToDate(from: stringDateOfCreation) {
            return TodoItem(id: id,
                            text: text,
                            priority: priority,
                            deadline: stringToDate(from: stringDeadline),
                            isCompleted: isCompleted,
                            dateOfCreation: dateOfCreation,
                            dateOfChange: stringToDate(from: stringDateOfChange))
        }

        return nil
     }

    var json: Any {
        assert(!Thread.isMainThread)
        func dateToString(from date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .short

            return dateFormatter.string(from: date)
        }

        var dictionary: [String: Any] = [JsonKeys.id.rawValue: id,
                                          JsonKeys.text.rawValue: text,
                                          JsonKeys.isCompleted.rawValue: isCompleted,
                                          JsonKeys.dateOfCreation.rawValue: dateToString(from: dateOfCreation)]
        if priority != .common {
            dictionary[JsonKeys.priority.rawValue] = priority.rawValue
        }

        if let deadline = deadline {
            dictionary[JsonKeys.deadline.rawValue] = dateToString(from: deadline)
        }

        if let dateOfChange = dateOfChange {
            dictionary[JsonKeys.dateOfChange.rawValue] = dateToString(from: dateOfChange)
        }

        return dictionary
    }
}

// MARK: Equatable для TodoItem

extension TodoItem: Equatable {
    static func ==(lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
}
