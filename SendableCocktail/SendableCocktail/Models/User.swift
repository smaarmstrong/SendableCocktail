import Foundation
import SwiftData

/// Defines the User model and its DTO (Data Transfer Object) representation.
/// The User model represents a user with a name and their associated favorites lists.
@Model
class User {
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

final class UserDTO: Sendable, Identifiable, Hashable {
  let name: String
  let favorites: [FavoritesDTO]?

  init(
    name: String,
    favorites: [FavoritesDTO]? = nil
  ) {
    self.name = name
    self.favorites = favorites
  }

  static func == (lhs: UserDTO, rhs: UserDTO) -> Bool {
    lhs.name == rhs.name
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
  }
}
