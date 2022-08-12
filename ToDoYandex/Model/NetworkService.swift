import Foundation

protocol NetworkService {
    func getAllTodoItems(
    completion: @escaping (Result<[TodoItem], Error>) -> Void
    )

    func editTodoItem(
    _ item: TodoItem,
    completion: @escaping (Result<TodoItem, Error>) -> Void
    )

    func deleteTodoItem(
    at id: String,
    completion: @escaping (Result<TodoItem, Error>) -> Void
    )
}

class Network: NetworkService {
    func getAllTodoItems(completion: @escaping (Result<[TodoItem], Error>) -> Void) {
        //
    }

    func editTodoItem(_ item: TodoItem, completion: @escaping (Result<TodoItem, Error>) -> Void) {
        //
    }

    func deleteTodoItem(at id: String, completion: @escaping (Result<TodoItem, Error>) -> Void) {
        //
    }

}
