//
//  AcronymsController.swift
//  
//
//  Created by tw on 2023/03/22.
//

import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let acronymsRoutes = routes.grouped("api", "acronyms")
        acronymsRoutes.get(use: getAllHandler(_:))
        
        acronymsRoutes.post(use: createHandler(_:))
        acronymsRoutes.get(":acronymID", use: getHandler(_:))
        acronymsRoutes.put(":acronymID", use: updateHandler(_:))
        acronymsRoutes.delete(":acronymID", use: deleteHandler(_:))
        acronymsRoutes.get("search", use: searchHandler(_:))
        acronymsRoutes.get("first", use: getFirstHandler(_:))
        acronymsRoutes.get("sorted", use: sortedHandler(_:))
        acronymsRoutes.get(":acronymID", "user", use: getUserHandler)
        acronymsRoutes.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler(_:))
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
        Acronym.query(on: req.db).all()
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
        // 1
        let data = try req.content.decode(CreateAcronymData.self)
        // 2
        let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
        return acronym.save(on: req.db).map { acronym }
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Acronym> {
      Acronym.find(req.parameters.get("acronymID"), on: req.db)
        .unwrap(or: Abort(.notFound))
    }
    
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
      let updateData = try req.content.decode(CreateAcronymData.self)
      return Acronym
        .find(req.parameters.get("acronymID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMap { acronym in
          acronym.short = updateData.short
          acronym.long = updateData.long
          acronym.$user.id = updateData.userID
          return acronym.save(on: req.db).map { acronym }
        }
    }
    
    func deleteHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
      Acronym.find(req.parameters.get("acronymID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMap { acronym in acronym.delete(on: req.db)
        .transform(to: .noContent)}
    }
    
    func searchHandler(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
      guard let searchTerm = req.query[String.self, at: "term"] else {
          throw Abort(.badRequest)
      }
        
      return Acronym.query(on: req.db).group(.or) { or in
        or.filter(\.$short == searchTerm)
        or.filter(\.$long == searchTerm)}
        .all()
    }
    
    func getFirstHandler(_ req: Request) -> EventLoopFuture<Acronym> {
      return Acronym.query(on: req.db)
        .first()
        .unwrap(or: Abort(.notFound))
    }
    
    func sortedHandler(_ req: Request) -> EventLoopFuture<[Acronym]> {
      return Acronym.query(on: req.db).sort(\.$short, .ascending).all()
    }
    
    func getUserHandler(_ req: Request) -> EventLoopFuture<User> {
      
      Acronym.find(req.parameters.get("acronymID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMap { acronym in
          acronym.$user.get(on: req.db)
        }
    }
    
    func addCategoriesHandler(_ req: Request) -> EventLoopFuture<HTTPStatus> {
      
      let acronymQuery =
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
          .unwrap(or: Abort(.notFound))
      let categoryQuery =
        Category.find(req.parameters.get("categoryID"), on: req.db)
          .unwrap(or: Abort(.notFound))
      
      return acronymQuery.and(categoryQuery)
        .flatMap { acronym, category in
          acronym
            .$categories
            .attach(category, on: req.db)
            .transform(to: .created)
    } }
}

struct CreateAcronymData: Content {
  let short: String
  let long: String
  let userID: UUID
}
