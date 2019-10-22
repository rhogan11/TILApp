import Vapor
import FluentPostgreSQL

final class Category: Codable {
    var id: Int?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Category {
    
    static func addCategory(_ name: String, to acronym: Acronym, on request: Request) throws -> Future<Void> {
        return Category.query(on: request).filter(\.name == name).first().flatMap(to: Void.self) { foundCategory in
            if let existingCategory = foundCategory {
                return acronym.categories.attach(existingCategory, on: request).transform(to: ())
            } else {
                let category = Category(name: name)
                return category.save(on: request).flatMap(to: Void.self) { savedCategory in
                    acronym.categories.attach(savedCategory, on: request).transform(to: ())
                }
            }
        }
    }
      
    var acronyms: Siblings<Category, Acronym, AcronymCategoryPivot> {
        return siblings()
    }
}

extension Category: PostgreSQLModel {}
extension Category: Migration {}
extension Category: Content {}
extension Category: Parameter {}
