import Fluent
import Vapor
import NIO

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req -> String in
        "Hello, world!"
    }
    
    // controller version
    let acronymsController = AcronymsController()
    try app.register(collection: acronymsController)
}
