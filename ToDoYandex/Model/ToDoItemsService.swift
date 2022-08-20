import Foundation
import CocoaLumberjack

protocol ItemsService {
    func load()
    func save()
    func add()
    func remove()
}

class ToDoItemsService {
    private enum Constants {
        static let queueName = "com.ToDoItemServiceQueue"
    }

    private var _todoItems: [TodoItem] {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.updateView()
            }
        }
    }

    var todoItems: [TodoItem] {
        get {
            queue.sync { [weak self] in
                return self?._todoItems ?? [TodoItem]()
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?._todoItems = newValue
            }
        }
    }

    let networkService: NetworkingService
    let filename: String
    let fileCache: FileCacheService
    private let queue: DispatchQueue
    weak var delegate: ToDoItemsServiceDelegate?

    init(filename: String) {
        self._todoItems = []
        self.queue = DispatchQueue(label: Constants.queueName, attributes: .concurrent)
        self.fileCache = FileCache()
        self.networkService = Network()
        self.filename = filename
    }

    func addNew(item: TodoItem) {
        add(newItem: item)
        fileCache.addNew(item)
        networkService.add(item: item) { result in
            switch result {
            case .success(let returnItem):
                print(returnItem)
            case .failure(let error):
                print(error)
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
        self.fileCache.loadAllItems(from: filename) {[weak self] result in
            switch result {
            case .success(let newItems):
                self?.todoItems = newItems
                DDLogInfo("Загрузка данных из кэша прошла успешно")
            case .failure(let error):
                DDLogWarn(error)
            }
        }

        self.networkService.getAllTodoItems {[weak self] result in
            switch result {
            case .success(let newItems):
                self?.todoItems = newItems.map { TodoItem(networkItem: $0) }
                print("Succes")
            case .failure:
                print("error")
            }
        }

        self.networkService.updateTodoItems(items: self.todoItems) {[weak self] result in
            switch result {
            case .success(let items):
                self?.todoItems = items.map { TodoItem(networkItem: $0) }
            case .failure(let error):
                print(error)
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
