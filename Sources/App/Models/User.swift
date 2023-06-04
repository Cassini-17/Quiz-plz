//
//  User.swift
//  
//
//  Created by Cassini17 on 31.05.2023.
//

import Fluent
import Vapor

final class User: Model {
    
    static let schema = "users"
    
    @ID(key: .id) var id: UUID?
    
    @Field(key: "name") var name: String

    @Field(key: "username") var username: String
    
    @Field(key: "password") var password: String
    
    @Children(for: \.$user) var questions: [Question]
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }
    
    // Public View of User (hides password from response message)
    final class Public: Content {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

// Saving user
extension User: Content {}

// Convert User (syncrhonously)
extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

// Converts Array of users to Public
extension Collection where Element: User {
    func convertToPublic() -> [User.Public] {
        return self.map { $0.convertToPublic() }
    }
}

// HTTP Basic Authentication
extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    
    static let passwordHashKey = \User.$password
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}

// Save and retrieve user as a part of the session
extension User: ModelSessionAuthenticatable {}

// Authenticate users with username and password
extension User: ModelCredentialsAuthenticatable {}







