//
//  CreateCategory.swift
//  
//
//  Created by Cassini17 on 26.05.2023.
//

import Fluent

struct CreateCategory: AsyncMigration {
    
    // Create schema
    func prepare(on database: Database) async throws {
        try await database.schema("categories")
        .id()
        .field("name", .string, .required)
        .unique(on: "name")
        .create()
    }
    
    // Delete schema
    func revert(on database: Database) async throws {
        try await database.schema("categories").delete()
    }
}
