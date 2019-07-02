import Foundation
import FluentPostgreSQL

final class AcronymCategoryPivot: PostgreSQLUUIDPivot {
    typealias Left = Acronym
    typealias Right = Category
 
    static let leftIDKey: LeftIDKey = \.acronymID
    static let rightIDKey: RightIDKey = \.categoryID
    
    var id: UUID?
    
    var acronymID: Acronym.ID
    var categoryID: Category.ID
    
    init(_ acronym: Acronym, _ category: Category) throws {
        self.acronymID = try acronym.requireID()
        self.categoryID = try category.requireID()
    }
}

extension AcronymCategoryPivot: Migration {}
extension AcronymCategoryPivot: ModifiablePivot {}
