import Foundation
import CocoaLumberjack

typealias todoItemsNetworkServiceComplition = (Result<[TodoItemNetworking], Error>) -> Void
typealias todoItemNetworkServiceComplition = (Result<TodoItemNetworking, Error>) -> Void

protocol NetworkingService {
    func getAllTodoItems(
    completion: @escaping todoItemsNetworkServiceComplition
    )

    func editTodoItem(
    _ item: TodoItem,
    completion: @escaping todoItemNetworkServiceComplition
    )

    func remove(
    item: TodoItem,
    completion: @escaping todoItemNetworkServiceComplition
    )

    func add(
        item: TodoItem,
        completion: @escaping todoItemNetworkServiceComplition
    )

    func getItem(
        id: String,
        completion: @escaping todoItemNetworkServiceComplition
    )

    func updateTodoItems(
        items: [TodoItem],
        completion: @escaping todoItemsNetworkServiceComplition
    )
}

class Network: NetworkingService {

    private enum Constants {
        static let url = "https://beta.mrdekk.ru/todobackend/list"
        static let queueName = "com.NetworkServiceQueue"
        static let bearerCode = "GuideToSimpleFestivals"
        static let revisionKeyForUserDefaults = "revision"
    }

    var revision: Int?

    private var postHeader: [String: String]? {
        guard let revision = revision else {
            return nil
        }

        return ["Authorization": "Bearer \(Constants.bearerCode)",
         "X-Last-Known-Revision": "\(revision)",
        "Content-Type": "application/json"]
    }

    private lazy var getHeader: [String: String] = {
        return ["Authorization": "Bearer \(Constants.bearerCode)"]
    }()

    private let queue: DispatchQueue

    init() {
        queue = DispatchQueue(label: Constants.queueName)
        revision = UserDefaults.standard.value(forKey: Constants.revisionKeyForUserDefaults) as? Int
    }

    func add(item: TodoItem, completion: @escaping todoItemNetworkServiceComplition) {
        guard let postHeader = postHeader else {
            completion(.failure(NetwrokError.unsynchronizedData))
            return
        }

        guard let url = URL(string: Constants.url) else {
            completion(.failure(NetwrokError.invalidURL))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = postHeader
        let responseAdd = RequestAddOrUpdateItem(element: TodoItemNetworking(item: item))

        do {
            urlRequest.httpBody = try JSONEncoder().encode(responseAdd)
        } catch {
            completion(.failure(error))
            return
        }

        queue.async {
            let task = URLSession.shared.dataTask(with: urlRequest) {[weak self] data, response, error in
                assert(!Thread.isMainThread)
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let response = response as? HTTPURLResponse, let data = data {
                    do {
                        try self?.process(statusCode: response.statusCode)
                        let response = try JSONDecoder().decode(ResponseElement.self, from: data)
                        let item = response.element
                        self?.revision = response.revision
                        completion(.success(item))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
            task.resume()
        }
    }

    func getItem(id: String, completion: @escaping todoItemNetworkServiceComplition) {
        guard let url = URL(string: Constants.url.appending("/\(id)")) else {
            completion(.failure(NetwrokError.invalidURL))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.allHTTPHeaderFields = getHeader
        queue.async {
            let task = URLSession.shared.dataTask(with: urlRequest) {[weak self] data, response, error in
                assert(!Thread.isMainThread)
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let response = response as? HTTPURLResponse, let data = data {
                    do {
                        try self?.process(statusCode: response.statusCode)
                        let response = try JSONDecoder().decode(ResponseElement.self, from: data)
                        let item = response.element
                        self?.revision = response.revision
                        completion(.success(item))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
            task.resume()
        }
    }

    func updateTodoItems(items: [TodoItem], completion: @escaping todoItemsNetworkServiceComplition) {
        guard let postHeader = postHeader else {
            completion(.failure(NetwrokError.unsynchronizedData))
            return
        }
        guard let url = URL(string: Constants.url) else {
            completion(.failure(NetwrokError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PATCH"
        urlRequest.allHTTPHeaderFields = postHeader
        let updatePatch = ResponseUpdatePatch(list: items.map { TodoItemNetworking(item: $0) })

        do {
            urlRequest.httpBody = try JSONEncoder().encode(updatePatch)
        } catch {
            completion(.failure(error))
            return
        }

        queue.async {
            let task = URLSession.shared.dataTask(with: urlRequest) {[weak self] data, response, error in
                assert(!Thread.isMainThread)
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let response = response as? HTTPURLResponse, let data = data {
                    do {
                        try self?.process(statusCode: response.statusCode)
                        let response = try JSONDecoder().decode(ResponseList.self, from: data)
                        let items = response.list
                        self?.revision = response.revision
                        completion(.success(items))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
            task.resume()
        }

    }

    func getAllTodoItems(completion: @escaping todoItemsNetworkServiceComplition) {
        guard let url = URL(string: Constants.url) else {
            completion(.failure(NetwrokError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.allHTTPHeaderFields = getHeader

        queue.async {
            let task = URLSession.shared.dataTask(with: urlRequest) {[weak self] data, response, error in
                assert(!Thread.isMainThread)
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let response = response as? HTTPURLResponse, let data = data {
                    do {
                        try self?.process(statusCode: response.statusCode)
                        let response = try JSONDecoder().decode(ResponseList.self, from: data)
                        let item = response.list
                        self?.revision = response.revision
                        completion(.success(item))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
            task.resume()
        }
    }

    func editTodoItem(_ item: TodoItem, completion: @escaping todoItemNetworkServiceComplition) {
        guard let postHeader = postHeader else {
            completion(.failure(NetwrokError.unsynchronizedData))
            return
        }

        guard let url = URL(string: Constants.url.appending("/\(item.id)")) else {
            completion(.failure(NetwrokError.invalidURL))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.allHTTPHeaderFields = postHeader
        let responseAdd = RequestAddOrUpdateItem(element: TodoItemNetworking(item: item))

        do {
            urlRequest.httpBody = try JSONEncoder().encode(responseAdd)
        } catch {
            completion(.failure(error))
            return
        }
        queue.async {
            let task = URLSession.shared.dataTask(with: urlRequest) {[weak self] data, response, error in
                assert(!Thread.isMainThread)
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let response = response as? HTTPURLResponse, let data = data {
                    do {
                        try self?.process(statusCode: response.statusCode)
                        let response = try JSONDecoder().decode(ResponseElement.self, from: data)
                        let item = response.element
                        self?.revision = response.revision
                        completion(.success(item))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
            task.resume()
        }
    }

    func remove(item: TodoItem, completion: @escaping todoItemNetworkServiceComplition) {
        guard let postHeader = postHeader else {
            completion(.failure(NetwrokError.unsynchronizedData))
            return
        }

        guard let url = URL(string: Constants.url.appending("/\(item.id)")) else {
            completion(.failure(NetwrokError.invalidURL))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
        urlRequest.allHTTPHeaderFields = postHeader
        queue.async {
            let task = URLSession.shared.dataTask(with: urlRequest) {[weak self] data, response, error in
                assert(!Thread.isMainThread)
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let response = response as? HTTPURLResponse, let data = data {
                    do {
                        try self?.process(statusCode: response.statusCode)
                        let response = try JSONDecoder().decode(ResponseElement.self, from: data)
                        let item = response.element
                        self?.revision = response.revision
                        completion(.success(item))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
            task.resume()
        }
    }

    private func process(statusCode: Int) throws {
        switch statusCode {
        case 400:
            throw NetwrokError.unsynchronizedData
        case 401:
            throw NetwrokError.invalidAuthorization
        case 404:
            throw NetwrokError.itemHasNotBeenFound
        case 500:
            throw NetwrokError.internalServerError
        default:
            break
        }
    }

}

enum NetwrokError: Error {
    case invalidURL
    case unsynchronizedData
    case itemHasNotBeenFound
    case invalidAuthorization
    case internalServerError
}
