//
//  QuestionsController.swift
//  
//
//  Created by Cassini17 on 25.05.2023.
//

import Vapor
import Fluent

struct QuestionsController: RouteCollection {

    // MARK: register routes and requests
    func boot(routes: RoutesBuilder) throws {
        let questionRoutes = routes.grouped("api", "questions")
        questionRoutes.get(use: getAllHandler)
        questionRoutes.get(":questionID", use: getHandler)
        questionRoutes.get(":questionID", "categories", use: getCategoriesOfQuestionHandler)
        
        // Auth
        let tokenAuthMiddleWare = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = questionRoutes.grouped(tokenAuthMiddleWare, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(":questionID", use: updateHandler)
        tokenAuthGroup.delete(":questionID", use: deleteHandler)
    }
    
    // MARK: - GET requests
   
    // Get all possible questions
    // Path: api/questions
    func getAllHandler(_ req: Request) async throws -> [Question] {
        return try await Question.query(on: req.db).all()
    }
    
    // Get a single question using question id parameter
    // Path: api/questions/:questionID
    func getHandler(_ req: Request) async throws -> Question {
        guard let question = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        return question
    }
    
    // Get categories that are attached to a given question
    // Path: api/questions/:questionID/categories
    func getCategoriesOfQuestionHandler(_ req: Request) async throws -> [Category] {
        guard let question = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        let categories = try await question.$categories.get(on: req.db)
        return categories
    }
    
    func getUserHandler(_ req: Request) async throws -> User.Public {
        guard let question = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        let user = try await question.$user.get(on: req.db)
        return user.convertToPublic()
    }
    
    // MARK: - POST requests
    
    // Create new question
    // Path: api/questions
    func createHandler(_ req: Request) async throws -> Question {
        let user = try req.auth.require(User.self)
        //let userID = try user.requireID()
        let data = try req.content.decode(CreateQuestionData.self)
        let question = try Question(text: data.text, imageURL: data.imageURL, userID: user.requireID())
        try await question.save(on: req.db)
        return question
    }
    
    // MARK: - PUT requests
    
    // Update a single question using question id parameter
    // Path: api/questions/:questionID
    func updateHandler(_ req: Request) async throws -> Question {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let updatedQuestion = try req.content.decode(CreateQuestionData.self)
        guard let question = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        
        question.text = updatedQuestion.text
        question.imageURL = updatedQuestion.imageURL
        question.$user.id = userID
        
        try await question.save(on: req.db)
        return question
    }
    
    // MARK: - DELETE requests
    
    // Delete a single question with its associated answers relation using question id parameter
    // Path: api/questions/:questionID
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let question = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        do {
            try await question.delete(force: true, on: req.db)
            return .noContent
        } catch {
            throw Abort(.expectationFailed, reason: "\(#line) cant delete \(error)")
        }
    }
    
    // MARK: - Data Transfer Object
    struct CreateQuestionData: Content {
        let text: String
        let imageURL: String
    }
    
}
