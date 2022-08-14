import Foundation

protocol NetworkService {
    func getAllTodoItems(
    completion: @escaping (Result<[TodoItem], Error>) -> Void
    )

    func editTodoItem(
    _ item: TodoItem,
    completion: @escaping (Result<TodoItem, Error>) -> Void
    )

    func remove(
    item: TodoItem,
    completion: @escaping (Result<TodoItem, Error>) -> Void
    )
}

class Network: NetworkService {

    let queue: DispatchQueue

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func getAllTodoItems(completion: @escaping (Result<[TodoItem], Error>) -> Void) {
        let timeout = TimeInterval.random(in: 1..<3)
        queue.asyncAfter(deadline: .now() + timeout, flags: .barrier) {
            assert(!Thread.isMainThread)
            //
        }
    }

    func editTodoItem(_ item: TodoItem, completion: @escaping (Result<TodoItem, Error>) -> Void) {
        let timeout = TimeInterval.random(in: 1..<3)
        queue.asyncAfter(deadline: .now() + timeout) {
            assert(!Thread.isMainThread)
            //
        }
    }

    func remove(item: TodoItem, completion: @escaping (Result<TodoItem, Error>) -> Void) {
        let timeout = TimeInterval.random(in: 1..<3)
        queue.asyncAfter(deadline: .now() + timeout) {
            assert(!Thread.isMainThread)
            //
        }
    }

}
