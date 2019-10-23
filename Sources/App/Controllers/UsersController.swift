import Vapor
import Crypto

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        usersRoute.get(User.parameter, use: self.getHandler)
        usersRoute.get(use: self.getAllHandler)
        usersRoute.get(User.parameter, "acronyms", use: self.getAcronymsHandler)
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: self.loginHandler )
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(User.self, use: self.createHandler)
    }
    
    private func createHandler(_ request: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: request).convertToPublic()
    }
    
    private func getAllHandler(_ request: Request) -> Future<[User.Public]> {
        return User.query(on: request).decode(data: User.Public.self).all()
    }
    
    private func getHandler(_ request: Request) throws -> Future<User.Public> {
        return try request.parameters.next(User.self).convertToPublic()
    }
    
    private func getAcronymsHandler(_ request: Request) throws -> Future<[Acronym]> {
        return try request.parameters.next(User.self).flatMap(to: [Acronym].self) { user in
            return try user.acronyms.query(on: request).all()
        }
    }
    
    private func loginHandler(_ request: Request) throws -> Future<Token> {
        let user = try request.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: request)
    }
}
