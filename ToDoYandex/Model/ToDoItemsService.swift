import Foundation
import CocoaLumberjack

typealias todoItemServiceComplition = (Result<TodoItem, Error>) -> Void
typealias resultServiceComplition = (Result<Void, Error>) -> Void

protocol ItemsService {
    func load(complition: @escaping resultServiceComplition)
    func save(complition: @escaping resultServiceComplition)
    func addNew(item: TodoItem, complition: @escaping todoItemServiceComplition)
    func remove(item: TodoItem, complition: @escaping todoItemServiceComplition)
    func editItem(item: TodoItem, complition: @escaping todoItemServiceComplition)
}

class ToDoItemsService: ItemsService {

    private enum Constants {
        static let queueName = "com.ToDoItemServiceQueue"
        static let firstLaunchKey = "firstLaunch"
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

    private var _todoItems: [TodoItem] {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.updateView()
            }
        }
    }

    private var isFirstLaunch: Bool {
        if UserDefaults.standard.bool(forKey: Constants.firstLaunchKey) {
            return false
        } else {
            UserDefaults.standard.set(true, forKey: Constants.firstLaunchKey)
            return true
        }
    }

    private var isDirty = false
    private let networkService: NetworkingService
    private let filename: String
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

    func editItem(item: TodoItem, complition: @escaping todoItemServiceComplition) {
        if isDirty {
            self.synchronize { [weak self] result in
                guard let service = self else { return }
                switch result {
                case .success(let networkItems):
                    service.todoItems = networkItems.map { TodoItem(networkItem: $0) }
                    service.fileCache.updateItems(service.todoItems)
                    self?.networkService.editTodoItem(item) { [weak self] result in
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
                case .failure(let error):
                    service.edit(item: item)
                    service.fileCache.edit(item)
                    complition(.failure(error))
                }
            }
            return
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

    func addNew(item: TodoItem, complition: @escaping todoItemServiceComplition) {
        if isDirty {
            self.synchronize { [weak self] result in
                guard let service = self else { return }
                switch result {
                case .success(let networkItems):
                    service.todoItems = networkItems.map { TodoItem(networkItem: $0) }
                    service.fileCache.updateItems(service.todoItems)
                    self?.networkService.add(item: item) { [weak self] result in
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
                case .failure(let error):
                    service.add(newItem: item)
                    service.fileCache.addNew(item)
                    complition(.failure(error))
                }
            }
            return
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

    func remove(item: TodoItem, complition: @escaping todoItemServiceComplition) {
        if isDirty {
            self.synchronize { [weak self] result in
                guard let service = self else { return }
                switch result {
                case .success(let networkItems):
                    service.todoItems = networkItems.map { TodoItem(networkItem: $0) }
                    service.fileCache.updateItems(service.todoItems)
                    self?.networkService.remove(item: item) { [weak self] result in
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
                case .failure(let error):
                    self?.delete(item: item)
                    self?.fileCache.remove(item)
                    complition(.failure(error))
                }
            }
            return
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

    func load(complition: @escaping resultServiceComplition) {
        self.fileCache.loadAllItems(from: filename) { [weak self] result in
            guard let service = self else { return }
            switch result {
            case .success(let newItems):
                service.todoItems = newItems
            case .failure(let error):
                DispatchQueue.main.async {
                    complition(.failure(error))
                }
            }

            if service.isFirstLaunch {
                service.networkService.getAllTodoItems { [weak self] result in
                    guard let service = self else { return }
                    switch result {
                    case .success(let networkingItems):
                        service.todoItems = networkingItems.compactMap { TodoItem(networkItem: $0) }
                        service.fileCache.updateItems(service.todoItems)
                        complition(.success(()))
                    case .failure(let error):
                        service.isDirty = true
                        complition(.failure(error))
                    }
                }
                return
            }

            service.networkService.updateTodoItems(items: service.todoItems) { [weak self] result in
                switch result {
                case .success(let networkItems):
                    let items = networkItems.map { TodoItem(networkItem: $0) }
                    self?.todoItems = items
                    self?.fileCache.updateItems(items)
                    complition(.success(()))
                case .failure(let error):
                    self?.isDirty = true
                    complition(.failure(error))
                }
            }
        }
    }

    func save(complition: @escaping resultServiceComplition) {
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

    private func synchronize(complition: @escaping todoItemsNetworkServiceComplition) {
        self.networkService.updateTodoItems(items: self.todoItems) { [weak self] result in
            switch result {
            case .success(let items):
                self?.isDirty = false
                complition(.success(items))
            case .failure(let error):
                self?.isDirty = true
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
