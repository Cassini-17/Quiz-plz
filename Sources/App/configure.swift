import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)

    // Configuring database for heroku
    if let databaseURL = Environment.get("DATABASE_URL") {
        var configuration = try SQLPostgresConfiguration(url: databaseURL)
        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.certificateVerification = .none
        let nioSSLContext = try NIOSSLContext(configuration: tlsConfig)
        configuration.coreConfiguration.tls = .require(nioSSLContext)
        app.databases.use(.postgres(configuration: configuration), as: .psql)
    } else {
        // Running on localhost
        app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)
    }


    // Migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateQuestion())
    app.migrations.add(CreateAnswer())
    app.migrations.add(CreateCategory())
    app.migrations.add(CreateQuestionCategoryPivot())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateAdminUser())
   
    // debug messsages
    app.logger.logLevel = .debug

    // add custom leaf tags
    app.leaf.tags["atIndex"] = IndexTag()
    
    // render leaf views
    app.views.use(.leaf)
    
    // auto-migration
    try await app.autoMigrate()

    // register routes
    try routes(app)
}
