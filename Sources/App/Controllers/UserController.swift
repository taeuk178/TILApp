//
//  UserController.swift
//  
//
//  Created by tw on 2023/03/22.
//

import Vapor

struct UsersController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("api", "users")
        usersRoute.post(use: createHandler)
        
        usersRoute.get(use: getAllHandler(_:))
        usersRoute.get(":userID", use: getHandler(_:))
        usersRoute.get(":userID", "acronyms", use: getAcronymsHandler)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<User> {
        let user = try req.content.decode(User.self)
        return user.save(on: req.db).map { user }
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[User]> {
      User.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<User> {
      User.find(req.parameters.get("userID"), on: req.db)
          .unwrap(or: Abort(.notFound))
    }
    
    func getAcronymsHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
      
      User.find(req.parameters.get("userID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMap { user in
          user.$acronyms.get(on: req.db)
        }
    }
}
