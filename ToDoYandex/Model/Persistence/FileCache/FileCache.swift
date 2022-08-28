import Foundation
import CocoaLumberjack
import SQLite

final class FileCache: PersistenceService {
    private enum Constants {
        static let queueName = "com.FileCacheServiceQueue"
        static let id = Expression<String>("id")
        static let text = Expression<String>("text")
        static let priority = Expression<String>("priority")
        static let isCompleted = Expression<Bool>("isCompleted")
        static let dateOfCreation = Expression<Date>("dateOfCreation")
        static let deadline = Expression<Date?>("deadline")
        static let dateOfChange = Expression<Date?>("dateOfChange")
    }

    private(set) var todoItems: [TodoItem]

    let queue: DispatchQueue

    private let items = Table("items")
    private let database: Connection

    init(filename: String) {
        self.queue = DispatchQueue(label: Constants.queueName)
        self.todoItems = []
        guard let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first else { fatalError() }

        do {
            self.database = try Connection("\(path)/\(filename.lowercased()).sqlite3") //
        } catch {
            print(error)
            fatalError()
        }
    }

    func load(from filename: String?, completion: @escaping loadPersistenceServiceCompletion) {
        do {
            let prepare: [TodoItemSQL] = try database.prepare(items).map { try $0.decode() }
            let todoItems = prepare.map { TodoItem(item: $0) }
            completion(.success(todoItems))
        } catch {
            self.createTable()
            completion(.failure(error))
        }
    }

    func save(to filename: String?, completion: @escaping savePersistenceServiceCompletion) {}

    @discardableResult func add(_ newItem: TodoItem) -> TodoItem? {
        do {
            try database.run(items.insert(TodoItemSQL(newItem)))
            return newItem
        } catch {
            DDLogError(error)
            return nil
        }
    }

    @discardableResult func remove(_ item: TodoItem) -> TodoItem? {
        let itemTable = items.filter(Constants.id == item.id)
        do {
            try database.run(itemTable.delete())
            return item
        } catch {
            DDLogWarn(error)
            return nil
        }
    }

    @discardableResult func edit(_ item: TodoItem) -> TodoItem? {
        let itemTable = items.filter(Constants.id == item.id)
        do {
            try database.run(itemTable.update(TodoItemSQL(item)))
            return item
        } catch {
            DDLogWarn(error)
            return nil
        }
    }

    func updateItems(_ newItems: [TodoItem]) {
        newItems.forEach {
            self.edit($0)
        }
    }

    private func createTable() {
        do {
            try self.database.run(items.create { t in
                t.column(Constants.id, primaryKey: true)
                t.column(Constants.text)
                t.column(Constants.priority)
                t.column(Constants.isCompleted)
                t.column(Constants.dateOfCreation)
                t.column(Constants.deadline)
                t.column(Constants.dateOfChange)
            })
        } catch {
            DDLogError(error)
        }
    }
}

extension TodoItem {
    init(item: TodoItemSQL) {
        self.id = item.id
        self.text = item.text
        self.isCompleted = item.isCompleted
        self.deadline = item.deadline
        self.dateOfChange = item.dateOfChange
        self.dateOfCreation = item.dateOfCreation
        switch item.priority {
        case "low":
            self.priority = .unimportant
        case "important":
            self.priority = .important
        default:
            self.priority = .common
        }
    }
}
