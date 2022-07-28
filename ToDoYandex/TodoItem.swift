import Foundation

struct TodoItem: Identifiable {
    let id: String
    let text: String
    let priority: Priority
    let deadline: Date?
    let isCompleted: Bool
    let dateOfCreation: Date
    let dateOfChange: Date?
    
    init(id: String = UUID().uuidString,text: String, priority: Priority,deadline: Date? = nil
         ,isCompleted: Bool = false, dateOfCreation: Date = Date.now, dateOfChange: Date? = nil) {
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
    
    func test() {
        
    }
}


//MARK: Парсинг JSON и его создание из структуры
extension TodoItem {
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
        
        guard let id = dictionary["id"] as? String,
              let text = dictionary["text"] as? String,
              let isCompleted = dictionary["isCompleted"] as? Bool,
              let stringDateOfCreation = dictionary["dateOfCreation"] as? String else {
            return nil
        }
        
        let priority = Priority(rawValue: dictionary["priority"] as? String ?? "Обычная") ?? .common
        let stringDeadline = dictionary["deadline"] as? String
        let stringDateOfChange = dictionary["dateOfChange"] as? String
        
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
        
        var dictionary: [String : Any] = ["id": id,"text": text, "isCompleted" : isCompleted,
                                          "dateOfCreation": dateToString(from: dateOfCreation)]
        if priority != .common {
            dictionary["priority"] = priority.rawValue
        }
        
        if let deadline = deadline {
            dictionary["deadline"] = dateToString(from: deadline)
        }
        
        if let dateOfChange = dateOfChange {
            dictionary["dateOfChange"] = dateToString(from: dateOfChange)
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
