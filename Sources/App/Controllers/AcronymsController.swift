import Fluent
import Vapor
import Authentication

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        acronymsRoutes.get(use: self.getAllHandler)
        acronymsRoutes.get("first", use: self.getFirsthandler)
        acronymsRoutes.get("search", use: self.searchAcronymHandler)
        acronymsRoutes.get("sorted", use: self.sortedHandler)
        acronymsRoutes.get(Acronym.parameter, use: self.getAcronymHandler)
        acronymsRoutes.get(Acronym.parameter, "user", use: self.getUserHandler)
        acronymsRoutes.get(Acronym.parameter, "categories", use: self.getCategoriesHandler)
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = acronymsRoutes.grouped(
          tokenAuthMiddleware,
          guardAuthMiddleware
        )
        tokenAuthGroup.post(AcronymCreateData.self, use: createHandler)
        tokenAuthGroup.delete(Acronym.parameter, use: deleteHandler)
        tokenAuthGroup.put(Acronym.parameter, use: updateHandler)
        tokenAuthGroup.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        tokenAuthGroup.delete(Acronym.parameter, "categories", Category.parameter, use: removeCategoriesHandler)
    }
    
    private func getAllHandler(_ request: Request) -> Future<[Acronym]> {
        return Acronym.query(on: request).all()
    }
    
    private func getAcronymHandler(_ request: Request) throws -> Future<Acronym> {
        return try request.parameters.next(Acronym.self)
    }

    private func searchAcronymHandler(_ request: Request) throws -> Future<[Acronym]> {
        guard let query = request.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        return Acronym.query(on: request).group(.or) { or in
            or.filter(\.short == query)
            or.filter(\.long == query)
        }.all()
    }

    private func createHandler(_ request: Request, data: AcronymCreateData) throws -> Future<Acronym> {
        let user = try request.requireAuthenticated(User.self)
        print(user.name)
        let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
        return acronym.save(on: request)
    }
    
    private func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.parameters
            .next(Acronym.self)
            .delete(on: request)
            .transform(to: HTTPStatus.noContent)
    }
    
    private func updateHandler(_ request: Request) throws -> Future<Acronym> {
        return try flatMap(
            to: Acronym.self,
            request.parameters.next(Acronym.self),
            request.content.decode(AcronymCreateData.self)
        ) { acronym, updateData in
            acronym.short = updateData.short
            acronym.long = updateData.long
            let user = try request.requireAuthenticated(User.self)
            acronym.userID = try user.requireID()
            return acronym.save(on: request)
        }
    }
    
    private func getFirsthandler(_ request: Request) throws -> Future<Acronym> {
        return Acronym.query(on: request).first().unwrap(or: Abort(.notFound))
    }
    
    private func sortedHandler(_ request: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: request).sort(\.short, .ascending).all()
    }
    
    private func getUserHandler(_ request: Request) throws -> Future<User.Public> {
        return try request.parameters.next(Acronym.self).flatMap(to: User.Public.self) { acronym in
            return acronym.user.get(on: request).convertToPublic()
        }
    }
    
    private func addCategoriesHandler(_ request: Request) throws -> Future<HTTPStatus> {
        return try flatMap(
            to: HTTPStatus.self,
            request.parameters.next(Acronym.self),
            request.parameters.next(Category.self)) { acronym, category in
                return acronym.categories
                    .attach(category, on: request)
                    .transform(to: .created)
        }
    }
    
    private func getCategoriesHandler(_ request: Request) throws -> Future<[Category]> {
        return try request.parameters.next(Acronym.self).flatMap(to: [Category].self) { acronym in
            return try acronym.categories.query(on: request).all()
        }
    }
    
    private func removeCategoriesHandler(_ request: Request) throws -> Future<HTTPStatus> {
        return flatMap(
            to: HTTPStatus.self,
            try request.parameters.next(Acronym.self),
            try request.parameters.next(Category.self)
        ) { acronym, category in
            return acronym.categories.detach(category, on: request).transform(to: .noContent)
        }
    }
}

struct AcronymCreateData: Content {
    let short: String
    let long: String
}
