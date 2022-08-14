import Foundation
import CocoaLumberjack

class ToDoItemsService {
    private enum Constants {
        static let queueName = "ToDoItemServiceQueue"
    }

    private(set) var todoItems: [TodoItem] {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.updateView()
            }
        }
    }

    let networkService: NetworkService
    let filename: String
    let fileCache: FileCacheService
    private let queue: DispatchQueue
    weak var delegate: ToDoItemsServiceDelegate?

    init(filename: String) {
        self.todoItems = []
        self.queue = DispatchQueue(label: Constants.queueName, qos: .utility, attributes: .concurrent)
        self.fileCache = FileCache(queue: queue)
        self.networkService = Network(queue: queue)
        self.filename = filename
    }

    func addNew(item: TodoItem) {
        fileCache.addNew(item)
        add(newItem: item)
        networkService.editTodoItem(item) { result in
            switch result {
            case .success(let addedItem):
                DDLogInfo("Item with ID: \(addedItem.id) has been added to the server")
            case .failure(let error):
                DDLogWarn(error)
            }
        }
    }

    func remove(item: TodoItem) {
        delete(item: item)
        fileCache.remove(item)
        networkService.remove(item: item) { result in
            switch result {
            case.success(let removedItem):
                DDLogInfo("Item with ID \(removedItem.id) has been removed from the server")
            case.failure(let error):
                DDLogWarn(error)
            }
        }
    }

    func load() {
        self.fileCache.loadAllItems(from: filename) { result in
            switch result {
            case .success(let newItems):
                self.todoItems.append(contentsOf: newItems)
                DDLogInfo("Загрузка данных из кэша прошла успешно")
            case .failure(let error):
                DDLogWarn(error)
            }
        }

        self.networkService.getAllTodoItems { result in
            switch result {
            case .success(let networkItems):
                for item in networkItems {
                    self.add(newItem: item)
                }
            case .failure(let error):
                DDLogWarn(error)
            }
        }
    }

    func save() {
        fileCache.saveAllItems(to: filename) { result in
            switch result {
            case .failure(let error):
                DDLogWarn(error)
            case .success:
                DDLogInfo("Сохранение прошло успешно")
            }
        }
    }

    private func add(newItem: TodoItem) {
        guard let index = todoItems.firstIndex(of: newItem) else {
            todoItems.append(newItem)
            DDLogInfo("Task with ID: \(newItem.id) have been added")
            return
        }
        let newItemDateOfChange = newItem.dateOfChange ?? newItem.dateOfCreation
        let itemDateOfChange = todoItems[index].dateOfChange ?? todoItems[index].dateOfCreation
        if itemDateOfChange < newItemDateOfChange {
            todoItems[index] = newItem
        }
        DDLogInfo("Task with ID: \(newItem.id) have been changed")
    }

    private func delete(item: TodoItem) {
        guard let index = todoItems.firstIndex(of: item) else {
            DDLogWarn("Item haven't been found")
            return
        }

        todoItems.remove(at: index)
    }
}

protocol ToDoItemsServiceDelegate: AnyObject {
    func updateView()
}
