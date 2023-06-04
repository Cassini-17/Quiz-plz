//
//  CategoriesController.swift
//  
//
//  Created by Cassini17 on 26.05.2023.
//

import Vapor
import Fluent

struct CategoriesController: RouteCollection {
    
    // MARK: register routes and requests
    func boot(routes: RoutesBuilder) throws {
        let categoriesRoutes = routes.grouped("api", "categories")
        categoriesRoutes.get(use: getAllHandler)
        categoriesRoutes.get(":categoryID", use: getHandler)
        categoriesRoutes.get(":categoryID", "questions", use: getQuestionsFromCategoryHandler)
        
        // Auth
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = categoriesRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.post(":categoryID", "questions", ":questionID", use: addCategoriesHandler)
        tokenAuthGroup.delete(":categoryID", "questions", ":questionID", use: addCategoriesHandler)
    }
    
    // MARK: - GET requests
    
    // Get all categories
    // Path: api/categories
    func getAllHandler(_ req: Request) async throws -> [Category] {
        return try await Category.query(on: req.db).all()
    }
    
    // Get single category using category id
    // Path: api/categories/:categoryID
    func getHandler(_ req: Request) async throws -> Category {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) category with such id is not found") }
        return category
    }
    
    // Get questions that are attached to a given category
    // Path: api/categories/:categoryID/questions
    func getQuestionsFromCategoryHandler(_ req: Request) async throws -> [Question] {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) category with such id is not found") }
        let questions = try await category.$questions.get(on: req.db)
        return questions
    }
    
    // MARK: - POST requests
    func createHandler(_ req: Request) async throws -> Category {
        let category = try req.content.decode(Category.self)
        try await category.save(on: req.db)
        return category
    }
    
    // Attach a question to a given category
    // Path: api/categories/:categoryID/questions/:questionID
    func addCategoriesHandler(_ req: Request) async throws -> Category {
        guard let categoryQuery = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) category with such id is not found") }
        guard let questionQuery = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        
        do {
            try await categoryQuery.$questions.attach(questionQuery, on: req.db)
            return categoryQuery
        } catch {
            throw Abort(.expectationFailed, reason: "\(#line) cannot attach question to category, \(error)")
        }
    }
    
    // MARK: - PUT requests
    
    // currently not implemented
    
    // MARK: - DELETE requests
    
    // Detach question from category
    // Path: api/categories/:categoryID/questions/:questionID
    func deleteCategoriesHandler(_ req: Request) async throws -> HTTPStatus {
        guard let categoryQuery = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) category with such id is not found") }
        guard let questionQuery = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        
        do {
            try await categoryQuery.$questions.detach(questionQuery, on: req.db)
            return .noContent
        } catch {
            throw Abort(.expectationFailed, reason: "\(#line) cannot detach qustion from category, \(error)")
        }
    }
    
    
    
    
    
    
}
