//
//  File.swift
//  
//
//  Created by Cassini17 on 31.05.2023.
//

import Vapor

struct UserController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let userRoutes = routes.grouped("api", "users")
        userRoutes.get(use: getAllHandler)
        userRoutes.get(":userID", use: getHandler)
        userRoutes.get(":userID", "questions", use: getQuestionsHandler)
        
        // Login
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = userRoutes.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        
        // Auth
        let tokenAuthMiddleware = User.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = userRoutes.grouped(tokenAuthMiddleware,guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
    }
    
    // Log In user
    func loginHandler(_ req: Request) async throws -> Token {
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        try await token.save(on: req.db)
        return token
    }
    
    // Returns a public representation of all users (password field is hidden)
    func getAllHandler(_ req: Request) async throws -> [User.Public] {
        let users = try await User.query(on: req.db).all()
        return users.convertToPublic()
    }
    
    // Get currently authenticcated user
    func getHandler(_ req: Request) async throws -> User.Public {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound, reason: "user with such id is not found")
        }
        return user.convertToPublic()
    }
    
    // Returns all questions that the user has created
    func getQuestionsHandler(_ req: Request) async throws -> [Question] {
        guard let user = try await User.find(req.parameters.get("userID"), on: req.db) else {
            throw Abort(.notFound, reason: "user with such id is not found")
        }
        let questions = try await user.$questions.get(on: req.db)
        return questions
        
    }
    
    func createHandler(_ req: Request) async throws -> User.Public {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)
        try await user.save(on: req.db)
        return user.convertToPublic()
    }
    
}
