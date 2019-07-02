import Fluent
import Vapor

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoutes = router.grouped("api", "acronyms")
        acronymsRoutes.post(use: self.createHandler)
        acronymsRoutes.get(use: self.getAllHandler)
        acronymsRoutes.get("first", use: self.getFirsthandler)
        acronymsRoutes.get("search", use: self.searchAcronymHandler)
        acronymsRoutes.get("sorted", use: self.sortedHandler)
        acronymsRoutes.get(Acronym.parameter, use: self.getAcronymHandler)
        acronymsRoutes.delete(Acronym.parameter, use: self.deleteHandler)
        acronymsRoutes.put(Acronym.parameter, use: self.updateHandler)
        acronymsRoutes.get(Acronym.parameter, "user", use: self.getUserHandler)
        acronymsRoutes.post(Acronym.parameter, "categories", Category.parameter, use: self.addCategoriesHandler)
        acronymsRoutes.get(Acronym.parameter, "categories", use: self.getCategoriesHandler)
        acronymsRoutes.delete(Acronym.parameter, "categories", Category.parameter, use: self.removeCategoriesHandler)
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

    private func createHandler(_ request: Request) throws -> Future<Acronym> {
        return try request.content.decode(Acronym.self).flatMap { acronym in
            return acronym.save(on: request)
        }
    }
    
    private func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.parameters
            .next(Acronym.self)
            .delete(on: request)
            .transform(to: HTTPStatus.noContent)
    }
    
    private func updateHandler(_ request: Request) throws -> Future<Acronym> {
        return flatMap(
            to: Acronym.self,
            try request.parameters.next(Acronym.self),
            try request.content.decode(Acronym.self)) { acronym, update in
                acronym.short = update.short
                acronym.long = update.long
                acronym.userID = update.userID
                return acronym.save(on: request)
        }
    }
    
    private func getFirsthandler(_ request: Request) throws -> Future<Acronym> {
        return Acronym.query(on: request).first().unwrap(or: Abort(.notFound))
    }
    
    private func sortedHandler(_ request: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: request).sort(\.short, .ascending).all()
    }
    
    private func getUserHandler(_ request: Request) throws -> Future<User> {
        return try request.parameters.next(Acronym.self).flatMap(to: User.self) { acronym in
            return acronym.user.get(on: request)
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

