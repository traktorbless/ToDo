import Foundation

typealias savePersistenceServiceCompletion = (CompletionResult<Void, Error>) -> Void
typealias loadPersistenceServiceCompletion = (CompletionResult<[TodoItem], Error>) -> Void
typealias itemPersistenceServiceCompletion = (CompletionResult<TodoItem, Error>) -> Void

protocol PersistenceService {
    func load(from filename: String?, completion: @escaping loadPersistenceServiceCompletion)
    func save(to filename: String?, completion: @escaping savePersistenceServiceCompletion)
    @discardableResult func add(_ newItem: TodoItem) -> TodoItem?
    @discardableResult func remove(_ item: TodoItem) -> TodoItem?
    @discardableResult func edit(_ item: TodoItem) -> TodoItem?
    func updateItems(_ items: [TodoItem])
}

enum PersistenceServiceError: Error {
    case itemHasNotBeenFound
}

enum CompletionResult<Success, Failure> where Failure: Error {
    case success(Success)
    case failure(Failure)
}
