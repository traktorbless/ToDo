import Foundation
import CocoaLumberjack

protocol ItemsService {
    func load(complition: @escaping (Result<Void, Error>) -> Void)
    func save(complition: @escaping (Result<Void, Error>) -> Void)
    func addNew(item: TodoItem, complition: @escaping (Result<TodoItem, Error>) -> Void)
    func remove(item: TodoItem, complition: @escaping (Result<TodoItem, Error>) -> Void)
    func editItem(item: TodoItem, complition: @escaping (Result<TodoItem, Error>) -> Void)
}

class ToDoItemsService: ItemsService {

    private enum Constants {
        static let queueName = "com.ToDoItemServiceQueue"
        static let firstLaunchKey = "firstLaunch"
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

    var isFirstLaunch: Bool {
        if UserDefaults.standard.bool(forKey: Constants.firstLaunchKey) {
            return false
        } else {
            UserDefaults.standard.set(true, forKey: Constants.firstLaunchKey)
            return true
        }
    }

    var isDirty = false

    private let networkService: NetworkingService
    let filename: String
    private let fileCache: FileCacheService
    private let queue: DispatchQueue
    weak var delegate: ToDoItemsServiceDelegate?

    init(filename: String) {
        self._todoItems = []
        self.queue = DispatchQueue(label: Constants.queueName, attributes: .concurrent)
        self.fileCache = FileCache()
        self.networkService = Network()
        self.filename = filename
    }

    func editItem(item: TodoItem, complition: @escaping (Result<TodoItem, Error>) -> Void) {
        if isDirty {
            self.synchronize { [weak self] result in
                guard let service = self else { return }
                switch result {
                case .success(let networkItems):
                    service.todoItems = networkItems.map { TodoItem(networkItem: $0) }
                    service.fileCache.updateItems(service.todoItems)
                case .failure(let error):
                    service.edit(item: item)
                    service.fileCache.edit(item)
                    complition(.failure(error))
                    return
                }
            }
        }

        networkService.editTodoItem(item) { [weak self] result in
            switch result {
            case .success(let networkItem):
                let item = TodoItem(networkItem: networkItem)
                self?.edit(item: item)
                self?.fileCache.edit(item)
                complition(.success(item))
            case .failure(let error):
                self?.edit(item: item)
                self?.fileCache.edit(item)
                self?.isDirty = true
                complition(.failure(error))
            }
        }
    }

    func addNew(item: TodoItem, complition: @escaping (Result<TodoItem, Error>) -> Void) {
        if isDirty {
            self.synchronize { [weak self] result in
                guard let service = self else { return }
                switch result {
                case .success(let networkItems):
                    service.todoItems = networkItems.map { TodoItem(networkItem: $0) }
                    service.fileCache.updateItems(service.todoItems)
                case .failure(let error):
                    service.add(newItem: item)
                    service.fileCache.addNew(item)
                    complition(.failure(error))
                    return
                }
            }
        }

        networkService.add(item: item) { [weak self] result in
            switch result {
            case .success(let returnItem):
                self?.add(newItem: TodoItem(networkItem: returnItem))
                self?.fileCache.addNew(TodoItem(networkItem: returnItem))
                complition(.success(TodoItem(networkItem: returnItem)))
            case .failure(let error):
                self?.add(newItem: item)
                self?.fileCache.addNew(item)
                self?.isDirty = true
                complition(.failure(error))
            }
        }
    }

    func remove(item: TodoItem, complition: @escaping (Result<TodoItem, Error>) -> Void) {
        if isDirty {
            self.networkService.getAllTodoItems { [weak self] result in
                guard let service = self else { return }
                switch result {
                case .success:
                    service.networkService.updateTodoItems(items: service.todoItems) {[weak self] result in
                        guard let service = self else { return }
                        switch result {
                        case .success(let items):
                            service.todoItems = items.map { TodoItem(networkItem: $0) }
                            service.fileCache.updateItems(service.todoItems)
                            service.isDirty = false
                        case .failure(let error):
                            service.isDirty = true
                            service.delete(item: item)
                            service.fileCache.addNew(item)
                            complition(.failure(error))
                            return
                        }
                    }
                case .failure(let error):
                    service.isDirty = true
                    service.add(newItem: item)
                    service.fileCache.addNew(item)
                    complition(.failure(error))
                    return
                }
            }
        }

        networkService.remove(item: item) { [weak self] result in
            switch result {
            case.success(let removedItem):
                let item = TodoItem(networkItem: removedItem)
                self?.delete(item: item)
                self?.fileCache.remove(item)
                complition(.success(item))
            case.failure(let error):
                self?.delete(item: item)
                self?.fileCache.remove(item)
                self?.isDirty = true
                complition(.failure(error))
            }
        }
    }

    func load(complition: @escaping (Result<Void, Error>) -> Void) {
        self.fileCache.loadAllItems(from: filename) {[weak self] result in
            switch result {
            case .success(let newItems):
                self?.todoItems = newItems
            case .failure(let error):
                DispatchQueue.main.async {
                    complition(.failure(error))
                }
            }
        }

        self.networkService.getAllTodoItems { [weak self] result in
            guard let service = self else { return }
            switch result {
            case .success(let networkingItems):
                if service.isFirstLaunch {
                    service.todoItems = networkingItems.compactMap { TodoItem(networkItem: $0) }
                    return
                }

                service.networkService.updateTodoItems(items: service.todoItems) {[weak self] result in
                    switch result {
                    case .success(let items):
                        self?.todoItems = items.map { TodoItem(networkItem: $0) }
                    case .failure(let error):
                        self?.isDirty = true
                        complition(.failure(error))
                    }
                }
            case .failure(let error):
                self?.isDirty = true
                complition(.failure(error))
            }
        }
    }

    func save(complition: @escaping (Result<Void, Error>) -> Void) {
        fileCache.saveAllItems(to: filename) { result in
            switch result {
            case .success:
                complition(.success(()))
            case .failure(let error):
                complition(.failure(error))
            }
        }
    }

    private func add(newItem: TodoItem) {
        guard let _ = todoItems.firstIndex(of: newItem) else {
            todoItems.append(newItem)
            return
        }
    }

    private func edit(item: TodoItem) {
        guard let index = todoItems.firstIndex(of: item) else { return }
        let newItemDateOfChange = item.dateOfChange ?? item.dateOfCreation
        let itemDateOfChange = todoItems[index].dateOfChange ?? todoItems[index].dateOfCreation
        if itemDateOfChange < newItemDateOfChange {
            todoItems[index] = item
        }
    }

    private func synchronize(complition: @escaping (Result<[TodoItemNetworking], Error>) -> Void) {
        self.networkService.getAllTodoItems { [weak self] result in
            guard let service = self else { return }
            switch result {
            case .success:
                service.networkService.updateTodoItems(items: service.todoItems) {[weak self] result in
                    switch result {
                    case .success(let items):
                        complition(.success(items))
                        self?.isDirty = false
                    case .failure(let error):
                        self?.isDirty = true
                        complition(.failure(error))
                        return
                    }
                }
            case .failure(let error):
                service.isDirty = true
                complition(.failure(error))
                return
            }
        }
    }

    private func delete(item: TodoItem) {
        guard let index = todoItems.firstIndex(of: item) else {
            return
        }

        todoItems.remove(at: index)
    }
}

protocol ToDoItemsServiceDelegate: AnyObject {
    func updateView()
}
