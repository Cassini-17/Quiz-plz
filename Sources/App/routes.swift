import Fluent
import Vapor

func routes(_ app: Application) throws {
    // Controllers
    let questionsController = QuestionsController()
    let answersController = AnswersController()
    let categoriesController = CategoriesController()
    let websiteController = WebsiteController()
    let userController = UserController()
    
    // register route collections
    try app.register(collection: questionsController)
    try app.register(collection: answersController)
    try app.register(collection: categoriesController)
    try app.register(collection: websiteController)
    try app.register(collection: userController)
    
}
