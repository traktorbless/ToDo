import Foundation
import CocoaLumberjack

protocol FileCacheService {
  func saveAllItems(
    to filename: String,
    completion: @escaping (Result<Void, Error>) -> Void
  )

  func loadAllItems(
    from filename: String,
    completion: @escaping (Result<[TodoItem], Error>) -> Void
  )

  @discardableResult func addNew(_ newItem: TodoItem) -> TodoItem?

  @discardableResult func remove(_ item: TodoItem) -> TodoItem?
}

final class FileCache: FileCacheService {
    private(set) var todoItems: [TodoItem]

    let queue: DispatchQueue

    init(queue: DispatchQueue) {
        todoItems = [TodoItem]()
        self.queue = queue
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
        DDLogInfo("Task with ID: \(newItem.id) have been changed")
        return newItem
    }

    @discardableResult func remove(_ item: TodoItem) -> TodoItem? {
        let index = todoItems.firstIndex(of: item)
        if let index = index {
            return todoItems.remove(at: index)
        } else {
            DDLogWarn("Item haven't been found")
            return nil
        }
    }

    func saveAllItems(to filename: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let timeout = TimeInterval.random(in: 1..<3)
        do {
            let fileUrl = try self.getFileURL(of: filename)

            queue.asyncAfter(deadline: .now() + timeout) {
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
                completion(.success(print("Save have been success")))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func loadAllItems(from filename: String, completion: @escaping (Result<[TodoItem], Error>) -> Void) {
        let timeout = TimeInterval.random(in: 1..<3)
        queue.asyncAfter(deadline: .now() + timeout, flags: .barrier) {
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
