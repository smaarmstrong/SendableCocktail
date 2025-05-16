import Foundation
import SwiftData

/// Defines the Favorites model and its DTO (Data Transfer Object) representation.
/// The Favorites model represents a collection of favorite cocktails with a name and its associated cocktails.
@Model
class Favorites {
  var name: String
  
  @Relationship(deleteRule: .nullify, inverse: \Cocktail.favorites)
  var cocktails: [Cocktail]?
  
  var user: User?

  init(
    name: String,
    cocktails: [Cocktail]? = nil,
    user: User? = nil
  ) {
    self.name = name
    self.cocktails = cocktails
    self.user = user
  }
}

final class FavoritesDTO: Sendable, Identifiable, Hashable {
  let name: String
  let cocktails: [CocktailDTO]?
  let user: UserDTO?

  init(
    name: String,
    cocktails: [CocktailDTO]? = nil,
    user: UserDTO? = nil
  ) {
    self.name = name
    self.cocktails = cocktails
    self.user = user
  }

  static func == (lhs: FavoritesDTO, rhs: FavoritesDTO) -> Bool {
    lhs.name == rhs.name && lhs.cocktails?.map { $0.name } == rhs.cocktails?.map { $0.name }
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(cocktails?.map { $0.name }.joined(separator: ",") ?? "")
  }
}
