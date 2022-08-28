//
//  TodoItemCoreData+CoreDataClass.swift
//  ToDoYandex
//
//  Created by Антон Таранов on 25.08.2022.
//
//

import Foundation
import CoreData

@objc(TodoItemCoreData)
public class TodoItemCoreData: NSManagedObject {
    var unwrappedText: String {
        text ?? "Unknown text"
    }

    var unwrappedPriority: String {
        priority ?? "basic"
    }

    var unwrappedDateOfCreation: Date {
        dateOfCreation ?? Date()
    }

    var unwrappedID: String {
        id ?? "Unknown ID"
    }
}
