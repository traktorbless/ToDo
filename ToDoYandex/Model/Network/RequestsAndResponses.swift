import Foundation

struct RequestAddOrUpdateItem: Codable {
    let element: TodoItemNetworking
 }

struct ResponseElement: Codable {
    let status: String
    let element: TodoItemNetworking
    let revision: Int
}

struct ResponseList: Codable {
    let status: String
    let list: [TodoItemNetworking]
    let revision: Int
}

struct ResponseUpdatePatch: Codable {
    let list: [TodoItemNetworking]
}
