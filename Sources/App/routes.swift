import Vapor
import Fluent

public func routes(_ router: Router) throws {    
    try router.register(collection: AcronymsController())
    try router.register(collection: UsersController())
    try router.register(collection: CategoriesController())
}


