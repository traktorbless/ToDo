import Foundation
import CocoaLumberjack

typealias todoItemServiceComplition = (Result<TodoItem, Error>) -> Void
typealias resultServiceComplition = (Result<Void, Error>) -> Void

protocol ItemsService {
    func load(completion: @escaping resultServiceComplition)
    func save(completion: @escaping resultServiceComplition)
    func addNew(item: TodoItem, completion: @escaping todoItemServiceComplition)
    func remove(item: TodoItem, completion: @escaping todoItemServiceComplition)
    func editItem(item: TodoItem, completion: @escaping todoItemServiceComplition)
}

final class ToDoItemsService: ItemsService {

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
    private let persistenceService: PersistenceService
    private let queue: DispatchQueue
    weak var delegate: ToDoItemsServiceDelegate?

    init(filename: String) {
        self._todoItems = []
        self.queue = DispatchQueue(label: Constants.queueName, attributes: .concurrent)
        self.persistenceService = FileCache(filename: filename)
        self.networkService = Network()
        self.filename = filename
    }

    func editItem(item: TodoItem, completion: @escaping todoItemServiceComplition) {
        edit(item: item)
        persistenceService.edit(item)
        if isDirty {
            self.synchronize {result in
                switch result {
                case .success:
                    completion(.success(item))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }

        networkService.editTodoItem(item) { [weak self] result in
            switch result {
            case .success(let networkItem):
                let item = TodoItem(networkItem: networkItem)
                completion(.success(item))
            case .failure(let error):
                self?.isDirty = true
                completion(.failure(error))
            }
        }
    }

    func addNew(item: TodoItem, completion: @escaping todoItemServiceComplition) {
        add(newItem: item)
        persistenceService.add(item)
        if isDirty {
            self.synchronize { result in
                switch result {
                case .success:
                    completion(.success(item))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }

        networkService.add(item: item) { [weak self] result in
            switch result {
            case .success(let returnItem):
                completion(.success(TodoItem(networkItem: returnItem)))
            case .failure(let error):
                self?.isDirty = true
                completion(.failure(error))
            }
        }
    }

    func remove(item: TodoItem, completion: @escaping todoItemServiceComplition) {
        delete(item: item)
        persistenceService.remove(item)
        if isDirty {
            self.synchronize {result in
                switch result {
                case .success:
                    completion(.success(item))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }

        networkService.remove(item: item) { [weak self] result in
            switch result {
            case.success(let removedItem):
                let item = TodoItem(networkItem: removedItem)
                completion(.success(item))
            case.failure(let error):
                self?.isDirty = true
                completion(.failure(error))
            }
        }
    }

    func load(completion: @escaping resultServiceComplition) {
        if isFirstLaunch {
            networkService.getAllTodoItems { [weak self] result in
                guard let service = self else { return }
                switch result {
                case .success(let networkingItems):
                    let items = networkingItems.compactMap { TodoItem(networkItem: $0) }
                    service.todoItems = items
                    service.persistenceService.updateItems(items)
                    completion(.success(()))
                case .failure(let error):
                    service.isDirty = true
                    completion(.failure(error))
                }
            }
            return
        }

        persistenceService.load(from: nil) { [weak self] result in
            guard let service = self else {
                return
            }
            switch result {
            case .success(let items):
                self?.todoItems = items

                service.networkService.updateTodoItems(items: service.todoItems) { [weak self] result in
                    switch result {
                    case .success(let networkItems):
                        let items = networkItems.map { TodoItem(networkItem: $0) }
                        self?.todoItems = items
                        self?.persistenceService.updateItems(items)
                        completion(.success(()))
                    case .failure(let error):
                        self?.isDirty = true
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func save(completion: @escaping resultServiceComplition) {
        persistenceService.save(to: nil) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
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
            case .success(let networkItems):
                let items = networkItems.map { TodoItem(networkItem: $0) }
                self?.todoItems = items
                self?.persistenceService.updateItems(items)
                self?.isDirty = false
                complition(.success(networkItems))
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
