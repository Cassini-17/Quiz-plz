//
//  QuestionCategoryPivot.swift
//  
//
//  Created by Cassini17 on 26.05.2023.
//

import Vapor
import Fluent

final class QuestionCategoryPivot: Model {
    
    static let schema = "question-category-pivot"
    
    // Primary key
    @ID(key: .id) var id: UUID?
    
    // Foreign key
    @Parent(key: "questionID") var question: Question
    
    // Foreign key
    @Parent(key: "categoryID") var category: Category
    
    init() {}
    
    init(id: UUID? = nil, question: Question, category: Category) throws {
        self.id = id
        self.$question.id = try question.requireID()
        self.$category.id = try category.requireID()
    }
}
