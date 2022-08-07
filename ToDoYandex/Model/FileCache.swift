import Foundation

final class FileCache {
    private(set) var todoItems: [TodoItem] {
        didSet {
            delegate?.updateItems()
        }
    }
    
    var delegate: FileCacheDelegate?
    
    @discardableResult func addNew(task: TodoItem) -> TodoItem? {
        if !todoItems.contains(task) {
            todoItems.append(task)
            return task
        } else {
            return nil
        }
    }
    
    @discardableResult func remove(task: TodoItem) -> TodoItem? {
        let index = todoItems.firstIndex(of: task)
        if let index = index {
            return todoItems.remove(at: index)
        } else {
            return nil
        }
    }
    
    func saveAllItems(to filename: String) {
        guard let fileUrl = getFileURL(of: filename) else { return }
        
        var jsonItems = [[String : Any]]()
        for item in todoItems {
            if let json = item.json as? [String : Any] {
                jsonItems.append(json)
            }
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonItems, options: [])
            try data.write(to: fileUrl, options: [])
        } catch {
            print(error)
        }
    }
    
    func loadAllItems(from filename: String) {
        guard let fileUrl = getFileURL(of: filename) else { return }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            
            if let getJson = try JSONSerialization.jsonObject(with: data) as? [[String:Any]] {
                for item in getJson {
                    if let todoItem = TodoItem.parse(json: item) {
                        addNew(task: todoItem)
                    } else {
                        print("Item have not been parsed")
                    }
                }
            }
        } catch {
            print(error)
        }
    }
    
    private func getFileURL(of filename: String) -> URL? {
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        
        return documentsDirectoryUrl.appendingPathComponent("\(filename).json")
    }
    
    init(filename: String? = nil) {
        todoItems = [TodoItem]()
        if let filename = filename {
            loadAllItems(from: filename)
        }
    }
}

protocol FileCacheDelegate: AnyObject {
    func updateItems()
}
