import Vapor
import Fluent

public func routes(_ router: Router) throws {    
    try router.register(collection: AcronymsController())
}


