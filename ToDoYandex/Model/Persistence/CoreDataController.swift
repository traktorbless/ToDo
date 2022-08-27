import Foundation
import CoreData
import CocoaLumberjack

typealias savePersistenceServiceCompletion = (Result<Void, Error>) -> Void
typealias loadPersistenceServiceCompletion = (Result<[TodoItem], Error>) -> Void
typealias itemPersistenceServiceCompletion = (Result<TodoItem, Error>) -> Void

protocol PersistenceService {
    func load(to filename: String?, completion: @escaping loadPersistenceServiceCompletion)
    func save(to filename: String?, completion: @escaping savePersistenceServiceCompletion)
    func add(_ newItem: TodoItem) -> TodoItem?
    func remove(_ item: TodoItem) -> TodoItem?
    func edit(_ item: TodoItem) -> TodoItem?
    func updateItems(_ items: [TodoItem])
}

class CoreDataController: PersistenceService {
    private enum Constants {
        static let persistentContainerName = "TodoItemModel"
        static let entityName = "TodoItemCoreData"
    }

    private lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Constants.persistentContainerName)
        container.loadPersistentStores { _, error in
            _ = error.map { fatalError("\($0)") }
        }
        return container
    }()

    var mainContext: NSManagedObjectContext {
        container.viewContext
    }

    func load(to filename: String? = nil, completion: @escaping loadPersistenceServiceCompletion) {
        do {
            let items = try mainContext.fetch(TodoItemCoreData.fetchRequest()).map { TodoItem(coreDataItem: $0) }
            completion(.success(items))
        } catch {
            completion(.failure(error))
        }
    }

    func save(to filename: String? = nil, completion: @escaping savePersistenceServiceCompletion) {
        do {
            try mainContext.save()
        } catch {
            completion(.failure(error))
        }
    }

    @discardableResult func add(_ newItem: TodoItem) -> TodoItem? {
        let coreDataItem = TodoItemCoreData(context: mainContext)
        coreDataItem.id = newItem.id
        coreDataItem.text = newItem.text
        coreDataItem.isCompleted = newItem.isCompleted
        coreDataItem.dateOfCreation = newItem.dateOfCreation
        switch newItem.priority {
        case .common:
            coreDataItem.priority = "basic"
        case .important:
            coreDataItem.priority = "important"
        case .unimportant:
            coreDataItem.priority = "low"
        }
        coreDataItem.deadline = newItem.deadline
        coreDataItem.dateOfChange = newItem.dateOfChange
        return newItem
    }

    @discardableResult func remove(_ item: TodoItem) -> TodoItem? {
        guard let items = try? mainContext.fetch(TodoItemCoreData.fetchRequest()) else {
            DDLogError("Неудалось получить данные с контекста")
            return nil
        }
        guard let item = items.first(where: { items in
            items.unwrappedID == item.id
        }) else {
            DDLogWarn("Предмет с ID: \(item.id) не был найден в конекста")
            return nil
        }

        mainContext.delete(item)

        return TodoItem(coreDataItem: item)
    }

    @discardableResult func edit(_ item: TodoItem) -> TodoItem? {
        guard let items = try? mainContext.fetch(TodoItemCoreData.fetchRequest()) else {
            DDLogError("Неудалось получить данные с контекста")
            return nil
        }

        guard let coreDataItem = items.first(where: { items in
            items.unwrappedID == item.id
        }) else {
            DDLogWarn("Предмет с ID: \(item.id) не был найден в конекста")
            return nil
        }

        coreDataItem.dateOfChange = item.dateOfChange
        coreDataItem.deadline = item.deadline
        coreDataItem.text = item.text
        coreDataItem.isCompleted = item.isCompleted
        switch item.priority {
        case .common:
            coreDataItem.priority = "basic"
        case .important:
            coreDataItem.priority = "important"
        case .unimportant:
            coreDataItem.priority = "low"
        }

        return TodoItem(coreDataItem: coreDataItem)
    }

    func updateItems(_ items: [TodoItem]) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: Constants.entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try mainContext.execute(deleteRequest)
        } catch {
            DDLogError("Неудалось отчистить объекты в контексте. Произошла ошибка: \(error)")
        }

        for item in items {
            add(item)
        }
    }
}

enum PersistenceServiceError: Error {
    case itemHasNotBeenFound
}
