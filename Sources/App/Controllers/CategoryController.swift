//
//  CategoryController.swift
//  
//
//  Created by tw on 2023/03/23.
//

import Vapor

struct CategoriesController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let categoriesRoute = routes.grouped("api", "categories")
        categoriesRoute.post(use: createHandler)
        categoriesRoute.get(use: getAllHandler)
        categoriesRoute.get(":categoryID", use: getHandler)
    }
    
    func createHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let category = try req.content.decode(Category.self)
        return category.save(on: req.db).map { category }
    }
    
    func getAllHandler(_ req: Request) -> EventLoopFuture<[Category]> {
        Category.query(on: req.db).all()
    }
    
    func getHandler(_ req: Request) -> EventLoopFuture<Category> {
        
        Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
    }
}
