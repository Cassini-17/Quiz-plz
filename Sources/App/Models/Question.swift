//
//  Question.swift
//  
//
//  Created by Cassini17 on 25.05.2023.
//

import Vapor
import Fluent

final class Question: Model {
    
    static let schema = "questions"
    
    // Primary key
    @ID(key: .id) var id: UUID?
    
    @Field(key: "text") var text: String
    
    @Children(for: \.$question) var answers: [Answer]
    
    @Field(key: "image_url") var imageURL: String
    
    @Parent(key: "user_id") var user: User
    
    // Foreign key
    @Siblings(through: QuestionCategoryPivot.self, from: \.$question, to: \.$category) var categories: [Category]
    
    init() {}
    
    init(id: UUID? = nil, text: String, imageURL: String, userID: User.IDValue) {
        self.id = id
        self.text = text
        self.imageURL = imageURL
        self.$user.id = userID
    }
    
}

// MARK: Saving Question
extension Question: Content {}
