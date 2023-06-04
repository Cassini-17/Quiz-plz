//
//  CreateAnswer.swift
//  
//
//  Created by Cassini17 on 25.05.2023.
//

import Fluent

struct CreateAnswer: AsyncMigration {
    
    // Create schema
    func prepare(on database: Database) async throws {
        try await database.schema("answers")
        .id()
        .field("option", .string, .required)
        .field("is_correct", .bool, .required)
        .field("question_id", .uuid, .required, .references("questions", "id", onDelete: .cascade))
        .create()
    }
    
    // Delete schema
    func revert(on database: Database) async throws {
        try await database.schema("answers").delete()
    }
}

