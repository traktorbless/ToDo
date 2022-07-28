import Foundation

final class FileCache {
    private(set) var todoItems: [TodoItem]
    
    func addNew(task: TodoItem) {
        if !todoItems.contains(task) {
            todoItems.append(task)
        } else {
            print("The task already exists")
        }
    }
    
    func remove(task: TodoItem) {
        let index = todoItems.firstIndex(of: task)
        if let index = index {
            todoItems.remove(at: index)
        } else {
            print("Task with this id has not found")
        }
    }
    
    func saveAllItems(to filename: String) {
        if let documentDirectoryUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let fileUrl = documentDirectoryUrl.appendingPathComponent("\(filename).json")
            
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
    }
    
    func loadAllItems(from filename: String) {
        guard let documentsDirectoryUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        
        let fileUrl = documentsDirectoryUrl.appendingPathComponent("\(filename).json")
        do {
            let data = try Data(contentsOf: fileUrl)
            
            if let getJson = try? JSONSerialization.jsonObject(with: data) as? [[String:Any]] {
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
    
    init(filename: String? = nil) {
        todoItems = [TodoItem]()
        if let filename = filename {
            loadAllItems(from: filename)
        }
    }
}
