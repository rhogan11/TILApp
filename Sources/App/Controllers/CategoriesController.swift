import Vapor

struct CategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let categoriesRoute = router.grouped("api", "categories")
        categoriesRoute.get(use: self.getAllHandler)
        categoriesRoute.get(Category.parameter, use: self.getHandler)
        categoriesRoute.get(Category.parameter, "acronyms", use: self.getAcronymsHandler)
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = categoriesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(Category.self, use: self.createHandler)
    }
    
    private func createHandler(_ request: Request, category: Category) -> Future<Category> {
        return category.save(on: request)
    }
    
    private func getAllHandler(_ request: Request) -> Future<[Category]> {
        return Category.query(on: request).all()
    }
    
    private func getHandler(_ request: Request) throws -> Future<Category> {
        return try request.parameters.next(Category.self)
    }
    
    private func getAcronymsHandler(_ request: Request) throws -> Future<[Acronym]> {
        return try request.parameters.next(Category.self).flatMap(to: [Acronym].self) { category in
            return try category.acronyms.query(on: request).all()
        }
    }
}
