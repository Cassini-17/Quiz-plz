//
//  Category.swift
//  
//
//  Created by Cassini17 on 26.05.2023.
//

import Vapor
import Fluent

final class Category: Model {
    
    static let schema = "categories"
    
    // Primary key
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String
    
    // Foreign key
    @Siblings(through: QuestionCategoryPivot.self, from: \.$category, to: \.$question) var questions: [Question]
    
    init() {}
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
    
}

extension Category: Content {}

extension Category {
    static func addCategory(_ name: String, to question: Question, on req: Request) async throws -> Void {
        let foundCategory = try await Category.query(on: req.db).filter(\.$name == name).first()
        if let existingCategory = foundCategory {
            return try await question.$categories.attach(existingCategory, on: req.db)
        } else {
            let category = Category(name: name)
            try await category.save(on: req.db)
            return try await question.$categories.attach(category, on: req.db)
        }
        
    }
}
