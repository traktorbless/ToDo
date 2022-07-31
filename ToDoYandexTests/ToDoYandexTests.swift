import XCTest
@testable import ToDoYandex

class ToDoYandexTests: XCTestCase {
    var sutTodoItem: TodoItem!
    var sutFileCache: FileCache!
    let item1 = TodoItem(text: "School", priority: .unimportant)
    let item2 = TodoItem(id: "ID",text: "ABCDE", priority: .important)
    let item3 = TodoItem(id: "ID2", text: "Math", priority: .common)
    let item4 = TodoItem(id: "ID ", text: "Math", priority: .common)
    let item5 = TodoItem(id: "ID", text: "Math", priority: .common)
    let item6 = TodoItem(id: "ID", text: "CS", priority: .important)
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sutTodoItem = TodoItem(id: "ID", text: "Math", priority: .common)
        sutFileCache = FileCache()
    }

    override func tearDownWithError() throws {
        sutFileCache = nil
        try super.tearDownWithError()
    }
    
    func testTodoItemNotEquals() {
        XCTAssertNotEqual(item2, item1, "Ошибка! Они должны быть разными")
    }
    
    func testTodoItemEquals() {
        
        XCTAssertEqual(item2, item5, "Ошибка! Они должны быть одинаковыми")
    }
    
    func testTodoItemJsonWithCommonTask() {
        let item1JSON = sutTodoItem.json
        let item2 = TodoItem.parse(json: item1JSON)!
        XCTAssertEqual(sutTodoItem, item2, "Ошибка! Они должны быть одинаковыми")
        XCTAssertEqual(sutTodoItem.priority, item2.priority, "Приоритеты должны быть одинаковые со значением 'обычный'")
        XCTAssertEqual(sutTodoItem.text, item2.text, "Ошибка! Названия заданий разные")
        
    }
    
    func testTodoItemJsonWithNonCommonTask() {
        let item3 = TodoItem(text: "Работа", priority: .important)
        let item3JSON = item3.json
        let item4 = TodoItem.parse(json: item3JSON)!
        XCTAssertEqual(item3, item4, "Ошибка! Они должны быть одинаковые")
        XCTAssertEqual(item4.priority, .important, "Ошибка! Приоритет должен быть важным")
        XCTAssertEqual(item3.dateOfCreation.description, item4.dateOfCreation.description, "Ошибка! Даты должны быть одинаковыми")
    }
    
    func testAddNewItemToFileCache() {
        sutFileCache.addNew(task: sutTodoItem)
        XCTAssertEqual(sutFileCache.todoItems.count, 1, "Неверное количество заданий")
        sutFileCache.addNew(task: sutTodoItem)
        XCTAssertEqual(sutFileCache.todoItems.count, 1, "Неверное количество заданий. Тут должна сработать защита от дублирования")
        let item = TodoItem(text: "School", priority: .unimportant)
        sutFileCache.addNew(task: item)
        XCTAssertEqual(sutFileCache.todoItems.count, 2, "Неверное количество заданий")
    }
    
    func testRemoveTaskInFileCache() {
        sutFileCache.addNew(task: sutTodoItem)
        sutFileCache.remove(task: sutTodoItem)
        XCTAssertEqual(sutFileCache.todoItems.count, 0, "Неверное количество заданий")
        sutFileCache.addNew(task: item1)
        sutFileCache.addNew(task: item2)
        sutFileCache.remove(task: sutTodoItem)
        XCTAssertEqual(sutFileCache.todoItems.count, 1, "Неверное количество заданий")
        sutFileCache.remove(task: sutTodoItem)
        XCTAssertEqual(sutFileCache.todoItems.count, 1, "Неверное количество заданий")
    }
    
    func testSaveAndLoadTodoItemsInFileCache() {
        sutFileCache.addNew(task: item1)
        sutFileCache.addNew(task: item2)
        sutFileCache.addNew(task: item3)
        let items = sutFileCache.todoItems
        sutFileCache.saveAllItems(to: "TestFile")
        sutFileCache.remove(task: item1)
        sutFileCache.remove(task: item2)
        sutFileCache.remove(task: item3)
        sutFileCache.loadAllItems(from: "TestFile")
        XCTAssertEqual(sutFileCache.todoItems, items, "Ошибка! Набор заданий должен совпадать после загрузки")
    }

}
