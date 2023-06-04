//
//  WebsiteController.swift
//  
//
//  Created by Cassini17 on 26.05.2023.
//

import Vapor
import Fluent

struct WebsiteController: RouteCollection {
    
    // MARK: register routes and requests
    func boot(routes: RoutesBuilder) throws {
        let authSessionRoutes = routes.grouped(User.sessionAuthenticator())
        authSessionRoutes.get("login", use: loginHandler)
        
        let credentialRoutes = authSessionRoutes.grouped(User.credentialsAuthenticator())
        let protectedRoutes = authSessionRoutes.grouped(User.redirectMiddleware(path: "/login"))
    
        credentialRoutes.post("login", use: loginPostHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("categories", use: allCategoriesHandler)
        authSessionRoutes.get("categories", ":categoryID", use: categoryHandler)
        authSessionRoutes.get("questions", use: allQuestionsHandler)
        
        protectedRoutes.get("questions", "create", use: createQuestionHandler)
        protectedRoutes.get("questions", ":questionID", "edit", use: editQuestionHandler)
        protectedRoutes.get("categories", ":categoryID", "edit", use: editCategoryHandler)
        protectedRoutes.post("categories", ":categoryID", "edit", use: editCategoryPostHandler)
        protectedRoutes.post("categories", ":categoryID", "delete", use: deleteCategoryHandler)
        protectedRoutes.post("questions", "create", use: createQuestionPostHandler)
        protectedRoutes.post("questions",":questionID", "edit", use: editQuestionPostHandler)
        protectedRoutes.post("questions", ":questionID", "delete", use: deleteQuestionHandler)
    }
    
    // MARK: - Login
    
    func loginHandler(_ req: Request) async throws -> View {
        let context: LoginContext
        if let error = req.query[Bool.self, at: "error"], error {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        return try await req.view.render("login", context)
    }
    
    struct LoginContext: Encodable {
        let title = "Log In"
        let loginError: Bool
        
        init(loginError: Bool = false) {
            self.loginError = loginError
        }
    }
    
    func loginPostHandler(_ req: Request) async throws -> Response {
        if req.auth.has(User.self) {
            return req.redirect(to: "/")
        } else {
            let context = LoginContext(loginError: true)
            return try await req.view.render("login", context).encodeResponse(for: req)
        }
    }
    
    // MARK: - Logout
    
    func logoutHandler(_ req: Request) async throws -> Response {
        req.auth.logout(User.self)
        return req.redirect(to: "/")
    }
    
    //MARK: - Home page
    
    // Displays home page
    func indexHandler(_ req: Request) async throws -> View {
        let userLoggedIn = req.auth.has(User.self)
        let context = IndexContext(userLoggedIn: userLoggedIn)
        return try await req.view.render("index", context)
    }
    
    struct IndexContext: Encodable {
        let title = "Home"
        let userLoggedIn: Bool
    }
    
    //MARK: - Categories table
    
    // Displays a table view of all categories and their question count
    func allCategoriesHandler(_ req: Request) async throws -> View {
        let categories = try await Category.query(on: req.db).all()
        var info: [CategoryInfo] = []
        
        for category in categories {
            let count = try await category.$questions.query(on: req.db).count()
            let categoryInfo = CategoryInfo(id: category.id, name: category.name, questionsCount: count)
            info.append(categoryInfo)
        }
        
        let context = AllCategoriesContext(categories: info)
        return try await req.view.render("categories", context)
    }
    
    struct AllCategoriesContext: Encodable {
        let title = "Categories"
        let categories: [CategoryInfo]
    }
    
    struct CategoryInfo: Encodable {
        let id: UUID?
        let name: String
        let questionsCount: Int
    }
    
    // MARK: - All Questions table for a single category
    
    // Shows a table of all questions for selected category
    func categoryHandler(_ req: Request) async throws -> View {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) category with such id is not found") }
        let questions = try await category.$questions.get(on: req.db)
        
        var questionsWithAnswers: [QuestionWithAnswers] = []
        for question in questions {
            let answers = try await question.$answers.get(on: req.db)
            let user = try await question.$user.get(on: req.db)
            let questionWithAnswers = QuestionWithAnswers(id: question.id, text: question.text, imageURL: question.imageURL,username: user.username, answers: answers)
            questionsWithAnswers.append(questionWithAnswers)
        }
    
        let context = CategoryContext(title: category.name, category: category, questions: questionsWithAnswers)
        return try await req.view.render("category", context)
    }
    
    struct CategoryContext: Encodable {
        let title: String
        let category: Category
        let questions: [QuestionWithAnswers]
        
    }
    
    struct QuestionWithAnswers: Encodable {
        let id: UUID?
        let text: String
        let imageURL: String?
        let username: String
        let answers: [Answer]
    }
    
    // MARK: - Edit Category name using button in table
    
    // Shows a form with a single text field to edit category name
    func editCategoryHandler(_ req: Request) async throws -> View {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) category with such id is not found") }
        let context = EditCategoryContext(name: category.name)
        return try await req.view.render("editCategoryForm", context)
    }
    
    struct EditCategoryContext: Encodable {
        let editing = true
        let name: String
    }
    
    // POST and save new category name
    func editCategoryPostHandler(_ req: Request) async throws -> Response {
        let updatedData = try req.content.decode(EditCategoryData.self)
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) category with such id is not found") }
        category.name = updatedData.name
        try await category.save(on: req.db)
        return req.redirect(to: "/categories")
    }
    
    struct EditCategoryData: Content {
        let name: String
    }
    
    // MARK: - Delete a category using delete button in table
    
    // Category can only be deleted if it has no questions attached to it
    func deleteCategoryHandler(_ req: Request) async throws -> Response {
        guard let category = try await Category.find(req.parameters.get("categoryID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) category with such id is not found") }
        let questionsCount = try await category.$questions.query(on: req.db).count()
        if questionsCount == 0 {
            try await category.delete(force: true, on: req.db)
            return req.redirect(to: "/categories")
        } else {
            throw Abort(.methodNotAllowed, reason: "this category has questions in it")
        }
    }
    
    // MARK: - Shows a table with all posible questions across all categories
    
    func allQuestionsHandler(_ req: Request) async throws -> View {
        let questions = try await Question.query(on: req.db).all()
        
        var questionsWithAnswers: [QuestionWithAnswers] = []
        for question in questions {
            let answers = try await question.$answers.get(on: req.db)
            let user = try await question.$user.get(on: req.db)
            let questionWithAnswers = QuestionWithAnswers(id: question.id, text: question.text, imageURL: question.imageURL, username: user.username, answers: answers)
            questionsWithAnswers.append(questionWithAnswers)
        }
        
        return try await req.view.render("questionbank", ["questions" : questionsWithAnswers])
    }
    
    // MARK: - Shows a form to create a new question with possible answers
    func createQuestionHandler(_ req: Request) async throws -> View {
        let categories = try await Category.query(on: req.db).all()
        let context = CreateQuestionContext(categories: categories)
        return try await req.view.render("createQuestion", context)
    }
    
    struct CreateQuestionContext: Encodable {
        let title = "Create a question"
        let categories: [Category]
    }
    
    // POST data in the form, save answers with the question and attach question to a category
    func createQuestionPostHandler(_ req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        let data = try req.content.decode(CreateQuestionFormData.self)
        let question = try Question(text: data.text, imageURL: data.imageURL, userID: user.requireID())
        try await question.save(on: req.db)
        guard let id = question.id else { throw Abort(.internalServerError, reason: "question object doesn't exist") }
        for ans in data.answers {
            let answer = Answer(option: ans.option, isCorrect: ans.isCorrect, questionID: id)
            try await answer.save(on: req.db)
        }
        
        for category in data.categories ?? [] {
            try await Category.addCategory(category, to: question, on: req)
        }
        
        return req.redirect(to: "/questions")
    }
    
    struct CreateQuestionFormData: Content {
        let text: String
        let imageURL: String
        let answers: [AnswerData]
        let categories: [String]?
        
        struct AnswerData: Content {
            let option: String
            let isCorrect: Bool
        }
    }
    
    // MARK: - Edit question using a form
    
    func editQuestionHandler(_ req: Request) async throws -> View {
        guard let questionToEdit = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        let answers = try await questionToEdit.$answers.get(on: req.db)
        let categories = try await questionToEdit.$categories.get(on: req.db)
        let context = EditQuestionContext(text: questionToEdit.text, imageURL: questionToEdit.imageURL, answers: answers, categories: categories)
        return try await req.view.render("createQuestion", context)
    }
    
    // POST data from the form and save it
    func editQuestionPostHandler(_ req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let updateData = try req.content.decode(CreateQuestionFormData.self)
        guard let questionToEdit = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        questionToEdit.text = updateData.text
        questionToEdit.imageURL = updateData.imageURL
        questionToEdit.$user.id = userID
        
        try await questionToEdit.save(on: req.db)
        
        let existingAnswers = try await questionToEdit.$answers.get(on: req.db)
        
        // Updating answers
        for i in existingAnswers.indices {
            existingAnswers[i].option = updateData.answers[i].option
            existingAnswers[i].isCorrect = updateData.answers[i].isCorrect
            try await existingAnswers[i].save(on: req.db)
        }
        
        // Updating categories
        let existingCategories = try await questionToEdit.$categories.get(on: req.db)
        let existingCategoriesStringArray = existingCategories.map { $0.name }
        
        let existingSet = Set<String>(existingCategoriesStringArray)
        let newSet = Set<String>(updateData.categories ?? [])
        
        let categoriesToAdd = newSet.subtracting(existingSet)
        let categoriesToRemove = existingSet.subtracting(newSet)
        
        for newCategory in categoriesToAdd {
            try await Category.addCategory(newCategory, to: questionToEdit, on: req)
        }
        
        for categoryNameToRemove in categoriesToRemove {
            let categoryToRemove = existingCategories.first { $0.name == categoryNameToRemove }
            
            if let categoryToRemove = categoryToRemove {
                try await questionToEdit.$categories.detach(categoryToRemove, on: req.db)
            }
        }
        
        return req.redirect(to: "/questions")
    }
    
    struct EditQuestionContext: Encodable {
        let title = "Edit a question"
        let editing = true
        let text: String
        let imageURL: String?
        let answers: [Answer]
        let categories: [Category]?
    }
    
    // MARK: - Delete question altogether with its answers
    func deleteQuestionHandler(_ req: Request) async throws -> Response {
        guard let question = try await Question.find(req.parameters.get("questionID"), on: req.db) else { throw Abort(.notFound, reason: "\(#line) question with such id is not found") }
        try await question.delete(force: true, on: req.db)
        return req.redirect(to: "/questions")
    }
    
    
}
