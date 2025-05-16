import Foundation
import SwiftData

/// Defines the Cocktail model and its DTO (Data Transfer Object) representation.
/// The Cocktail model represents a cocktail with a name and its associated favorite lists.
@Model
class Cocktail {
  var name: String
  @Relationship(deleteRule: .cascade)
  var favorites: [Favorites]?

  init(
    name: String,
    favorites: [Favorites]? = nil
  ) {
    self.name = name
    self.favorites = favorites
  }
}

final class CocktailDTO: Sendable, Identifiable {
  let name: String
  let favorites: [FavoritesDTO]?

  init(
    name: String,
    favorites: [FavoritesDTO]? = nil
  ) {
    self.name = name
    self.favorites = favorites
  }
}
