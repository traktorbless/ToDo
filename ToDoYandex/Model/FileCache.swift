import Foundation
import CocoaLumberjack

typealias saveFileCacheServiceComplition = (Result<Void, Error>) -> Void
typealias loadFileCacheServiceComplition = (Result<[TodoItem], Error>) -> Void

protocol FileCacheService {
  func saveAllItems(
    to filename: String,
    completion: @escaping saveFileCacheServiceComplition
  )

  func loadAllItems(
    from filename: String,
    completion: @escaping loadFileCacheServiceComplition
  )

  @discardableResult func addNew(_ newItem: TodoItem) -> TodoItem?

  @discardableResult func remove(_ item: TodoItem) -> TodoItem?
}

final class FileCache: FileCacheService {
    private enum Constants {
        static let queueName = "com.FileCacheServiceQueue"
    }

    private(set) var todoItems: [TodoItem]

    let queue: DispatchQueue

    init() {
        todoItems = [TodoItem]()
        self.queue = DispatchQueue(label: Constants.queueName, attributes: .concurrent)
    }

    @discardableResult func addNew(_ newItem: TodoItem) -> TodoItem? {
        guard let index = todoItems.firstIndex(of: newItem) else {
            todoItems.append(newItem)
            DDLogInfo("Task with ID: \(newItem.id) have been added")
            return newItem
        }
        let newItemDateOfChange = newItem.dateOfChange ?? newItem.dateOfCreation
        let itemDateOfChange = todoItems[index].dateOfChange ?? todoItems[index].dateOfCreation
        if itemDateOfChange < newItemDateOfChange {
            todoItems[index] = newItem
        }
        DDLogInfo("Task with ID: \(newItem.id) have been changed in file cache")
        return newItem
    }

    @discardableResult func remove(_ item: TodoItem) -> TodoItem? {
        let index = todoItems.firstIndex(of: item)
        if let index = index {
            return todoItems.remove(at: index)
        } else {
            DDLogWarn("Item haven't been found in file cache")
            return nil
        }
    }

    func saveAllItems(to filename: String, completion: @escaping saveFileCacheServiceComplition) {
        do {
            let fileUrl = try self.getFileURL(of: filename)

            queue.async {
                assert(!Thread.isMainThread)
                var jsonItems = [[String: Any]]()
                for item in self.todoItems {
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

    func loadAllItems(from filename: String, completion: @escaping (Result<[TodoItem], Error>) -> Void) {
        queue.async(flags: .barrier) {
            assert(!Thread.isMainThread)
            do {
                let fileUrl = try self.getFileURL(of: filename)
                let data = try Data(contentsOf: fileUrl)

                guard let getJson = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    throw FileCacheErrors.unparsableData
                }

                var todoItems = [TodoItem]()
                for item in getJson {
                    if let todoItem = TodoItem.parse(json: item) {
                        todoItems.append(todoItem)
                    }
                }
                self.todoItems = todoItems
                completion(.success(todoItems))
            } catch {
                completion(.failure(error))
            }
        }
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
}
