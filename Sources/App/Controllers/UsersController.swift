import Vapor

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        usersRoute.post(User.self, use: self.createHandler)
        usersRoute.get(User.parameter, use: self.getHandler)
        usersRoute.get(use: self.getAllHandler)
        usersRoute.get(User.parameter, "acronyms", use: self.getAcronymsHandler)
    }
    
    private func createHandler(_ request: Request, user: User) throws -> Future<User> {
        return user.save(on: request)
    }
    
    private func getAllHandler(_ request: Request) -> Future<[User]> {
        return User.query(on: request).all()
    }
    
    private func getHandler(_ request: Request) throws -> Future<User> {
        return try request.parameters.next(User.self)
    }
    
    private func getAcronymsHandler(_ request: Request) throws -> Future<[Acronym]> {
        return try request.parameters.next(User.self).flatMap(to: [Acronym].self) { user in
            return try user.acronyms.query(on: request).all()
        }
    }
}
