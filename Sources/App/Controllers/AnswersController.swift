//
//  AnswersController.swift
//  
//
//  Created by Cassini17 on 25.05.2023.
//

import Vapor
import Fluent

struct AnswersController: RouteCollection {
    
    // MARK: register routes and requests
    func boot(routes: Vapor.RoutesBuilder) throws {
        let answerRoutes = routes.grouped("api", "answers")
        answerRoutes.get(use: getAllHandler)
        answerRoutes.get(":questionID", use: getAnswersForQuestionHandler)
        
        // Auth 
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = answerRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(":answerID", use: updateHandler)
        tokenAuthGroup.delete(":answerID", use: deleteHandler)
    }
    
    // MARK: - GET requests
   
    // Get all possible answers
    // Path: api/answers
    func getAllHandler(_ req: Request) async throws -> [Answer] {
        return try await Answer.query(on: req.db).all()
    }
    
    // Get all answers for a given question id
    // Path: api/answers/question
    func getAnswersForQuestionHandler(_ req: Request) async throws -> [Answer] {
        guard let question = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        return try await question.$answers.get(on: req.db)
    }
    
    // MARK: - POST requests
    
    // Create single answer by specifying a question id to which the answer will be attached to
    // Path: api/answers
    func createHandler(_ req: Request) async throws -> Answer {
        let data = try req.content.decode(CreateAnswerData.self)
        let answer = Answer(option: data.option, isCorrect: data.isCorrect, questionID: data.questionID)
        try await answer.save(on: req.db)
        return answer
    }
    
    // MARK: - PUT requests
    
    // Update a single answer using answer id parameter
    // Path: api/answers/:answerID
    func updateHandler(_ req: Request) async throws -> Answer {
        let updatedAnswer = try req.content.decode(CreateAnswerData.self)
        guard let answer = try await Answer.find(req.parameters.get("answerID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) answer with such id is not found") }
        
        answer.option = updatedAnswer.option
        answer.isCorrect = updatedAnswer.isCorrect
        answer.$question.id = updatedAnswer.questionID
        
        try await answer.save(on: req.db)
        return answer
    }
    
    // MARK: - DELETE requests
    
    // Delete a single answer using answer id parameter
    // Path: api/answers/:answerID
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let answer = try await Answer.find(req.parameters.get("answerID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) answer with such id is not found") }
        
        do {
            try await answer.delete(force: true, on: req.db)
            return .noContent
        } catch {
            throw Abort(.expectationFailed, reason: "\(#line) cant delete answer, \(error)")
        }
    }
    
    // MARK: - Data Transfer Object
    struct CreateAnswerData: Content {
        let option: String
        let isCorrect: Bool
        let questionID: UUID
    }

}
