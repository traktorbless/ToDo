import Foundation
import CocoaLumberjack

final class FileCache {
    private(set) var todoItems: [TodoItem] {
        didSet {
            delegate?.updateItems()
        }
    }

    var delegate: FileCacheDelegate?

    @discardableResult func addNew(task: TodoItem) -> TodoItem? {
        guard let index = todoItems.firstIndex(of: task) else {
            todoItems.append(task)
            DDLogInfo("Task with ID: \(task.id) have been added")
            return task
        }
        todoItems[index] = task
        DDLogInfo("Task with ID: \(task.id) have been changed")
        return task
    }

    @discardableResult func remove(task: TodoItem) -> TodoItem? {
        let index = todoItems.firstIndex(of: task)
        if let index = index {
            return todoItems.remove(at: index)
        } else {
            DDLogWarn("Item haven't been found")
            return nil
        }
    }

    func saveAllItems(to filename: String) throws {
        let fileUrl = try getFileURL(of: filename)

        var jsonItems = [[String: Any]]()
        for item in todoItems {
            if let json = item.json as? [String: Any] {
                jsonItems.append(json)
            }
        }

        let data = try JSONSerialization.data(withJSONObject: jsonItems, options: [])
        try data.write(to: fileUrl, options: [])
    }

    func loadAllItems(from filename: String) throws {
        let fileUrl = try getFileURL(of: filename)

        let data = try Data(contentsOf: fileUrl)

        guard let getJson = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw FileCacheErrors.unparsableData
        }

        for item in getJson {
            if let todoItem = TodoItem.parse(json: item) {
                addNew(task: todoItem)
            }
        }
    }

    private func getFileURL(of filename: String) throws -> URL {
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw FileCacheErrors.cannotFindSystemDirectory
        }

        return documentsDirectoryUrl.appendingPathComponent("\(filename).json")
    }

    init(filename: String? = nil) {
        todoItems = [TodoItem]()
        if let filename = filename {
            try? loadAllItems(from: filename)
        }
    }
}

enum FileCacheErrors: Error {
    case cannotFindSystemDirectory
    case unparsableData
}

protocol FileCacheDelegate: AnyObject {
    func updateItems()
}
