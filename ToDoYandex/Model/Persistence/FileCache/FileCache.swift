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
            DDLogError(error)
            fatalError()
        }
        self.createTable()
    }

    func load(from filename: String?, completion: @escaping loadPersistenceServiceCompletion) {
        queue.async { [weak self] in
            guard let fileCache = self else { return }
            do {
                let prepare: [TodoItemSQL] = try fileCache.database.prepare(fileCache.items).map { try $0.decode() }
                let todoItems = prepare.map { TodoItem(item: $0) }
                completion(.success(todoItems))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func save(to filename: String?, completion: @escaping savePersistenceServiceCompletion) {}

    @discardableResult func add(_ newItem: TodoItem) -> TodoItem? {
        queue.async { [weak self] in
            guard let fileCache = self else { return }
            do {
                try fileCache.database.run(fileCache.items.insert(TodoItemSQL(newItem)))
            } catch {
                DDLogError(error)
            }
        }
        return newItem
    }

    @discardableResult func remove(_ item: TodoItem) -> TodoItem? {
        queue.async { [weak self] in
            guard let fileCache = self else { return }
            let itemTable = fileCache.items.filter(Constants.id == item.id)
            do {
                try fileCache.database.run(itemTable.delete())
            } catch {
                DDLogWarn(error)
            }
        }
        return item
    }

    @discardableResult func edit(_ item: TodoItem) -> TodoItem? {
        queue.async { [weak self] in
            guard let fileCache = self else { return }
            let itemTable = fileCache.items.filter(Constants.id == item.id)
            do {
                try fileCache.database.run(itemTable.update(TodoItemSQL(item)))
            } catch {
                DDLogWarn(error)
            }
        }
        return item
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
