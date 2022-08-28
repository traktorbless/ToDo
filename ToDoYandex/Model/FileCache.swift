import Foundation
import CocoaLumberjack
import SQLite

// typealias saveFileCacheServiceCompletion = (CompletionResult<Void,Error>) -> Void
// typealias loadFileCacheServiceCompletion = (CompletionResult<[TodoItem],Error>) -> Void
//
// protocol FileCacheService {
//    func saveAllItems(
//    to filename: String,
//    completion: @escaping saveFileCacheServiceCompletion
//    )
//
//    func loadAllItems(
//    from filename: String,
//    completion: @escaping loadFileCacheServiceCompletion
//    )
//
//    @discardableResult func addNew(_ newItem: TodoItem) -> TodoItem?
//
//    @discardableResult func remove(_ item: TodoItem) -> TodoItem?
//
//    @discardableResult func edit(_ item: TodoItem) -> TodoItem?
//
//    func updateItems(_ newItems: [TodoItem])
// }

final class FileCache: PersistenceService {
    func load(from filename: String?, completion: @escaping loadPersistenceServiceCompletion) {
        //
    }

    func save(to filename: String?, completion: @escaping savePersistenceServiceCompletion) {
        //
    }

    func add(_ newItem: TodoItem) -> TodoItem? {
        //
        return nil
    }

    private enum Constants {
        static let queueName = "com.FileCacheServiceQueue"
    }

    private(set) var todoItems: [TodoItem]

    let queue: DispatchQueue

    init() {
        todoItems = [TodoItem]()
        queue = DispatchQueue(label: Constants.queueName, qos: .utility)
    }

    @discardableResult func addNew(_ newItem: TodoItem) -> TodoItem? {
        guard let _ = todoItems.firstIndex(of: newItem) else {
            todoItems.append(newItem)
            return newItem
        }
        return nil
    }

    @discardableResult func remove(_ item: TodoItem) -> TodoItem? {
        let index = todoItems.firstIndex(of: item)
        if let index = index {
            return todoItems.remove(at: index)
        } else {
            return nil
        }
    }

    @discardableResult func edit(_ item: TodoItem) -> TodoItem? {
        guard let itemIndex = todoItems.firstIndex(of: item) else { return nil }
        let newItemDateOfChange = item.dateOfChange ?? item.dateOfCreation
        let itemDateOfChange = todoItems[itemIndex].dateOfChange ?? todoItems[itemIndex].dateOfCreation
        if itemDateOfChange < newItemDateOfChange {
            todoItems[itemIndex] = item
        }
        return todoItems[itemIndex]
    }

    func saveAllItems(to filename: String, completion: @escaping savePersistenceServiceCompletion) {
        do {
            let fileUrl = try self.getFileURL(of: filename)

            queue.async { [weak self] in
                guard let service = self else {

                    completion(.failure(FileCacheErrors.cannotFindSystemDirectory))
                    return
                }
                assert(!Thread.isMainThread)
                var jsonItems = [[String: Any]]()
                for item in service.todoItems {
                    if let json = item.json as? [String: Any] {
                        jsonItems.append(json)
                    }
                }

                do {
                    assert(!Thread.isMainThread)
                    let data = try JSONSerialization.data(withJSONObject: jsonItems, options: [])
                    try data.write(to: fileUrl, options: [])
                } catch {
                    completion(.failure(error))
                }
                completion(.success(()))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func load(from filename: String, completion: @escaping loadPersistenceServiceCompletion) {
        queue.async { [weak self] in
            assert(!Thread.isMainThread)
            do {
                guard let fileUrl = try self?.getFileURL(of: filename) else {
                    completion(.failure(FileCacheErrors.cannotFindSystemDirectory))
                    return
                }
                let data = try Data(contentsOf: fileUrl)

                guard let getJson = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    throw FileCacheErrors.unparsableData
                }

                let todoItems = getJson.compactMap { TodoItem.parse(json: $0) }
                self?.todoItems = todoItems
                completion(.success(todoItems))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func updateItems(_ newItems: [TodoItem]) {
        self.todoItems = newItems
    }

    private func getFileURL(of filename: String) throws -> URL {
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FileCacheErrors.cannotFindSystemDirectory
        }

        return documentsDirectoryUrl.appendingPathComponent("\(filename).json")
    }
}

enum FileCacheErrors: Error {
    case cannotFindSystemDirectory
    case unparsableData
    case serializationError
}
