//
//  CreateQuestionCategoryPivot.swift
//  
//
//  Created by Cassini17 on 26.05.2023.
//

import Fluent

struct CreateQuestionCategoryPivot: AsyncMigration {
    
    // Create schema
    func prepare(on database: Database) async throws {
        try await database.schema("question-category-pivot")
        .id()
        .field("questionID", .uuid, .required, .references("questions", "id", onDelete: .cascade))
        .field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
        .create()
    }
    
    // Delete schema
    func revert(on database: Database) async throws {
        try await database.schema("question-category-pivot").delete()
    }
}
