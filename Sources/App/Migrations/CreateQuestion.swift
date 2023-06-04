//
//  CreateQuestion.swift
//  
//
//  Created by Cassini17 on 25.05.2023.
//

import Fluent

struct CreateQuestion: AsyncMigration {
    
    // Create schema
    func prepare(on database: Database) async throws {
        try await database.schema("questions")
        .id()
        .field("text", .string, .required)
        .field("image_url", .string, .required)
        .field("user_id", .uuid, .required, .references("users", "id"))
        .create()
    }
    
    // Delete schema 
    func revert(on database: Database) async throws {
        try await database.schema("questions").delete()
    }
}
