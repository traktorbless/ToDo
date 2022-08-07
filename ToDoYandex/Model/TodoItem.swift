import Foundation

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
         deadline: Date? = nil
         ,isCompleted: Bool = false,
         dateOfCreation: Date = Date.now,
         dateOfChange: Date? = nil) {
        self.id = id
        self.text = text
        self.priority = priority
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.dateOfCreation = dateOfCreation
        self.dateOfChange = dateOfChange
    }
    
    enum Priority: String {
        case important = "Важная"
        case unimportant = "Неважная"
        case common = "Обычная"
    }
    
    func makeCompleted() -> TodoItem {
        TodoItem(
            id: id,
            text: text,
            priority: priority,
            deadline: deadline,
            isCompleted: true,
            dateOfCreation: dateOfCreation,
            dateOfChange: Date.now
        )
    }
}


//MARK: Парсинг JSON и его создание из структуры
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
            return TodoItem(id: id, text: text, priority: priority, deadline: stringToDate(from: stringDeadline) , isCompleted: isCompleted, dateOfCreation: dateOfCreation, dateOfChange: stringToDate(from: stringDateOfChange))
        }
        
        return nil
     }
    
    var json: Any {
        func dateToString(from date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .medium
            dateFormatter.dateStyle = .short
            
            return dateFormatter.string(from: date)
        }
        
        var dictionary: [String : Any] = [JsonKeys.id.rawValue : id,
                                          JsonKeys.text.rawValue : text,
                                          JsonKeys.isCompleted.rawValue : isCompleted,
                                          JsonKeys.dateOfCreation.rawValue : dateToString(from: dateOfCreation)]
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

//MARK: Equatable для TodoItem

extension TodoItem: Equatable {
    static func ==(lhs: TodoItem, rhs: TodoItem) -> Bool {
        lhs.id == rhs.id
    }
}
