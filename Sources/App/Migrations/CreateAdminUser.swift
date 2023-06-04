//
//  CreateAdminUser.swift
//  
//
//  Created by Cassini17 on 01.06.2023.
//

import Fluent
import Vapor

struct CreateAdminUser: AsyncMigration {
    
    func prepare(on database: Database) async throws {
        // Running on LocalHost
        if let admin_username = Environment.get("admin_username"),
           let admin_password = Environment.get("admin_password") {
            let passwordHash: String
            passwordHash = try Bcrypt.hash(admin_password)
            let user = User(name: "Admin", username: admin_username, password: passwordHash)
            return try await user.save(on: database)
        } else {
            if  let admin_username_local = ProcessInfo.processInfo.environment["admin_username_local"],
                let admin_password_local = ProcessInfo.processInfo.environment["admin_password_local"] {
                let passwordHash: String
                passwordHash = try Bcrypt.hash(admin_password_local)
                let user = User(name: "Admin", username: admin_username_local, password: passwordHash)
                return try await user.save(on: database)
            }
        }
    }
    
    func revert(on database: Database) async throws {
        // Running on heroku
        if let admin_username = Environment.get("admin_username") {
            try await User.query(on: database).filter(\.$username == admin_username).delete()
        } else {
            // Running on local host
            if let admin_username_local = ProcessInfo.processInfo.environment["admin_username_local"] {
                try await User.query(on: database).filter(\.$username == admin_username_local).delete()
            }
        }
    }
}

