import Foundation

class ToDoItemsService {

    let networkService: NetworkService
    let fileCache: FileCacheService
    let queue: DispatchQueue

    init() {
        self.fileCache = FileCache(filename: "Files")
        self.networkService = Network()
        self.queue = DispatchQueue(label: "ToDoItemServiceQueue", qos: .utility, attributes: .concurrent)
    }
}
