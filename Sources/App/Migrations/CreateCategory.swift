//
//  CreateCategory.swift
//  
//
//  Created by tw on 2023/03/23.
//

import Fluent
struct CreateCategory: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .id()
            .field("name", .string, .required)
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories").delete()
    }
}
