//
//  TodoItemCoreData+CoreDataProperties.swift
//  ToDoYandex
//
//  Created by Антон Таранов on 25.08.2022.
//
//

import Foundation
import CoreData

extension TodoItemCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TodoItemCoreData> {
        return NSFetchRequest<TodoItemCoreData>(entityName: "TodoItemCoreData")
    }

    @NSManaged public var dateOfChange: Date?
    @NSManaged public var dateOfCreation: Date?
    @NSManaged public var deadline: Date?
    @NSManaged public var id: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var priority: String?
    @NSManaged public var text: String?
}

extension TodoItemCoreData: Identifiable {

}
