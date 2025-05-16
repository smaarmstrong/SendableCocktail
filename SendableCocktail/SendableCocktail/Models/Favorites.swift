import Foundation
import SwiftData

/// Defines the Favorites model and its DTO (Data Transfer Object) representation.
/// The Favorites model represents a collection of favorite cocktails with a name and its associated cocktails.
@Model
class Favorites {
  var name: String
  @Relationship(deleteRule: .cascade)
  var cocktails: [Cocktail]?
  
  init(
    name: String,
    cocktails: [Cocktail]? = nil
  ) {
    self.name = name
    self.cocktails = cocktails
  }
}

final class FavoritesDTO: Sendable, Identifiable, Hashable {
  let name: String
  let cocktails: [CocktailDTO]?
  
  init(
    name: String,
    cocktails: [CocktailDTO]? = nil
  ) {
    self.name = name
    self.cocktails = cocktails
  }
  
  static func == (lhs: FavoritesDTO, rhs: FavoritesDTO) -> Bool {
    lhs.name == rhs.name
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }
}

