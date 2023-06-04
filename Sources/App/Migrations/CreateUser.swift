//
//  CreateUser.swift
//  
//
//  Created by Cassini17 on 31.05.2023.
//

import Fluent
import Vapor

struct CreateUser: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        try await database.schema("users")
        .id()
        .field("name", .string, .required)
        .field("username", .string, .required)
        .field("password", .string, .required)
        .unique(on: "username")
        .create()
    }
    
    // Delete schema
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
    
    
}
