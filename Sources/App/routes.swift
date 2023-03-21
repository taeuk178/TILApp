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

    // MARK: - Create
    
//    app.post("api", "acronyms") { req -> EventLoopFuture<Acronym> in
//        let acronym = try req.content.decode(Acronym.self)
//        let result = acronym.save(on: req.db).map { acronym }
//        return result
//    }
    
    app.post("api", "acronyms") { req async throws -> Acronym in
        let acronym = try req.content.decode(Acronym.self)
        try await acronym.save(on: req.db)
        return acronym
    }
    
    // MARK: - Retrieve
    
    // 1 all acronym
//    app.get("api", "acronyms") { req -> EventLoopFuture<[Acronym]> in
//
//        Acronym.query(on: req.db).all()
//    }
    
    // async
//    app.get("api", "acronyms") { req async throws -> [Acronym] in
//        let acronymArray = try await Acronym.query(on: req.db).all()
//        return acronymArray
//    }
    
    // controller version
    let acronymsController = AcronymsController()
    try app.register(collection: acronymsController)
    

    // single acronym
    app.get("api", "acronyms", ":acronymID") {  req -> EventLoopFuture<Acronym> in
      Acronym.find(req.parameters.get("acronymID"), on: req.db)
        .unwrap(or: Abort(.notFound))
    }
    
    // MARK:  - Update

    app.put("api", "acronyms", ":acronymID") { req -> EventLoopFuture<Acronym> in
        let updatedAcronym = try req.content.decode(Acronym.self)
        return Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.short = updatedAcronym.short
                acronym.long = updatedAcronym.long
                return acronym.save(on: req.db).map {
                    acronym
                }
            }
    }

    // MARK: - Delete
    
    app.delete("api", "acronyms", ":acronymID") {
        req -> EventLoopFuture<HTTPStatus> in
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.delete(on: req.db)
                    .transform(to: .accepted)
            }
    }
    
    // MARK: - Filter
    
    app.get("api", "acronyms", "search") { req -> EventLoopFuture<[Acronym]> in
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Acronym.query(on: req.db)
            .filter(\.$short == searchTerm).limit(2)
            .all()
        
//        return Acronym.query(on: req.db).group(.or) { or in
//            or.filter(\.$short == searchTerm)
//            or.filter(\.$long == searchTerm)
//        }.all()
    }
    
    // MARK: - First Result
    
    app.get("api", "acronyms", "first") { req -> EventLoopFuture<Acronym> in
        Acronym.query(on: req.db)
            .first()
            .unwrap(or: Abort(.notFound))
    }
    
    // MARK: - Sorting Result
    
    app.get("api", "acronyms", "sorted") { req -> EventLoopFuture<[Acronym]> in
        Acronym.query(on: req.db)
            .sort(\.$short, .ascending)
            .all()
    }
}
