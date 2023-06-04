//
//  Answer.swift
//  
//
//  Created by Cassini17 on 25.05.2023.
//

import Vapor
import Fluent

final class Answer: Model {
    
    static let schema = "answers"
    
    // Fields
    
    // Primary key
    @ID(key: .id) var id: UUID?
    
    @Field(key: "option") var option: String
    
    @Field(key: "is_correct") var isCorrect: Bool
    
    // Foreign key
    @Parent(key: "question_id") var question: Question
    
    init() {}
    
    init(id: UUID? = nil, option: String, isCorrect: Bool, questionID: Question.IDValue) {
        self.id = id
        self.option = option
        self.isCorrect = isCorrect
        self.$question.id = questionID
    }
    
}

extension Answer: Content {}
