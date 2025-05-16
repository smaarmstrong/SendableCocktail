import Foundation
import SwiftData

/// Actor responsible for managing cocktail and favorites data operations.
/// Handles CRUD operations for cocktails and favorites, as well as managing relationships between them.
@available(iOS 17, *)
@ModelActor
actor CocktailModelActor: Sendable {
  private var context: ModelContext { modelExecutor.modelContext }

  // MARK: - User Operations

  func fetchUsers() async throws -> [UserDTO] {
    print("[ModelActor] Fetching users...")
    let fetchDescriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\User.name)])
    let users: [User] = try context.fetch(fetchDescriptor)
    print("[ModelActor] Fetched users: \(users.map { $0.name })")
    return users.map { user in
      UserDTO(
        name: user.name,
        favorites: user.favorites?.map { favorite in
          FavoritesDTO(
            name: favorite.name,
            cocktails: favorite.cocktails?.map { cocktail in
              CocktailDTO(
                name: cocktail.name,
                favorites: nil // Avoid circular reference
              )
            }
          )
        }
      )
    }
  }

  func createUser(name: String) async throws {
    print("[ModelActor] Creating user: \(name)")
    let user = User(name: name)
    context.insert(user)
    try context.save()
    print("[ModelActor] User created: \(name)")
  }

  // MARK: - Cocktail Operations

  func fetchCocktails() async throws -> [CocktailDTO] {
    print("[ModelActor] Fetching cocktails...")
    let fetchDescriptor = FetchDescriptor<Cocktail>(sortBy: [SortDescriptor(\Cocktail.name)])
    let cocktails: [Cocktail] = try context.fetch(fetchDescriptor)
    print("[ModelActor] Fetched cocktails: \(cocktails.map { $0.name })")
    return cocktails.map { cocktail in
      CocktailDTO(
        name: cocktail.name,
        favorites: cocktail.favorites?.map { favorite in
          FavoritesDTO(
            name: favorite.name,
            cocktails: nil // Avoid circular reference
          )
        }
      )
    }
  }

  func addCocktail(name: String) async throws {
    print("[ModelActor] Adding cocktail: \(name)")
    let cocktail = Cocktail(name: name)
    context.insert(cocktail)
    try context.save()
    print("[ModelActor] Cocktail added: \(name)")
  }

  func deleteCocktail(name: String) async throws {
    print("[ModelActor] Deleting cocktail: \(name)")
    let predicate = #Predicate<Cocktail> { cocktail in
      cocktail.name == name
    }
    let fetchDescriptor = FetchDescriptor<Cocktail>(predicate: predicate)
    let cocktails = try context.fetch(fetchDescriptor)

    for cocktail in cocktails {
      context.delete(cocktail)
    }
    try context.save()
    print("[ModelActor] Deleted cocktails named: \(name)")
  }

  // MARK: - Favorites Operations

  func fetchFavorites(forUser user: UserDTO?) async throws -> [FavoritesDTO] {
    print("[ModelActor] Fetching favorites for user: \(user?.name ?? "none")")
    let fetchDescriptor: FetchDescriptor<Favorites>
    
    if let userName = user?.name {
      let predicate = #Predicate<Favorites> { favorite in
        favorite.user?.name == userName
      }
      fetchDescriptor = FetchDescriptor<Favorites>(predicate: predicate, sortBy: [SortDescriptor(\Favorites.name)])
    } else {
      // Only show favorites with no user (unauthenticated)
      let predicate = #Predicate<Favorites> { favorite in
        favorite.user == nil
      }
      fetchDescriptor = FetchDescriptor<Favorites>(predicate: predicate, sortBy: [SortDescriptor(\Favorites.name)])
    }
    
    let favorites: [Favorites] = try context.fetch(fetchDescriptor)
    print("[ModelActor] Fetched favorites: \(favorites.map { $0.name })")
    return favorites.map { favorite in
      FavoritesDTO(
        name: favorite.name,
        cocktails: favorite.cocktails?.map { cocktail in
          CocktailDTO(
            name: cocktail.name,
            favorites: nil // Avoid circular reference
          )
        },
        user: favorite.user.map { user in
          UserDTO(name: user.name)
        }
      )
    }
  }

  func addFavorite(name: String, forUser user: UserDTO?) async throws {
    print("[ModelActor] Adding favorite: \(name) for user: \(user?.name ?? "none")")
    let favorite = Favorites(name: name)

    if let userName = user?.name {
      let predicate = #Predicate<User> { u in
        u.name == userName
      }
      let fetchDescriptor = FetchDescriptor<User>(predicate: predicate)
      if let existingUser = try context.fetch(fetchDescriptor).first {
        favorite.user = existingUser
      }
    }

    context.insert(favorite)
    try context.save()
    print("[ModelActor] Favorite added: \(name)")
  }

  func deleteFavorite(name: String) async throws {
    print("[ModelActor] Deleting favorite: \(name)")
    let predicate = #Predicate<Favorites> { favorite in
      favorite.name == name
    }
    let fetchDescriptor = FetchDescriptor<Favorites>(predicate: predicate)
    let favorites = try context.fetch(fetchDescriptor)

    for favorite in favorites {
      context.delete(favorite)
    }
    try context.save()
    print("[ModelActor] Deleted favorites named: \(name)")
  }

  // MARK: - Relationship Operations

  func addCocktailToFavorite(cocktailName: String, favoriteName: String) async throws {
    print("[ModelActor] Adding cocktail \(cocktailName) to favorite \(favoriteName)")
    let cocktailPredicate = #Predicate<Cocktail> { cocktail in
      cocktail.name == cocktailName
    }
    let favoritePredicate = #Predicate<Favorites> { favorite in
      favorite.name == favoriteName
    }

    let cocktailDescriptor = FetchDescriptor<Cocktail>(predicate: cocktailPredicate)
    let favoriteDescriptor = FetchDescriptor<Favorites>(predicate: favoritePredicate)

    let cocktails = try context.fetch(cocktailDescriptor)
    let favorites = try context.fetch(favoriteDescriptor)

    // If the cocktail doesn't exist, create it!
    let cocktail: Cocktail
    if let found = cocktails.first {
      cocktail = found
    } else {
      print("[ModelActor] Cocktail \(cocktailName) not found, creating it.")
      cocktail = Cocktail(name: cocktailName)
      context.insert(cocktail)
      try context.save()
    }

    guard let favorite = favorites.first else {
      print("[ModelActor] Favorite not found for add operation")
      throw NSError(domain: "CocktailModelActor", code: 404, userInfo: [NSLocalizedDescriptionKey: "Favorite not found"])
    }

    if favorite.cocktails == nil {
      favorite.cocktails = []
    }
    if !(favorite.cocktails?.contains(where: { $0.name == cocktailName }) ?? false) {
      favorite.cocktails?.append(cocktail)
    }

    if cocktail.favorites == nil {
      cocktail.favorites = []
    }
    if !(cocktail.favorites?.contains(where: { $0.name == favoriteName }) ?? false) {
      cocktail.favorites?.append(favorite)
    }

    try context.save()
    print("[ModelActor] Added cocktail \(cocktailName) to favorite \(favoriteName)")
  }

  func removeCocktailFromFavorite(cocktailName: String, favoriteName: String) async throws {
    print("[ModelActor] Removing cocktail \(cocktailName) from favorite \(favoriteName)")
    let cocktailPredicate = #Predicate<Cocktail> { cocktail in
      cocktail.name == cocktailName
    }
    let favoritePredicate = #Predicate<Favorites> { favorite in
      favorite.name == favoriteName
    }

    let cocktailDescriptor = FetchDescriptor<Cocktail>(predicate: cocktailPredicate)
    let favoriteDescriptor = FetchDescriptor<Favorites>(predicate: favoritePredicate)

    let cocktails = try context.fetch(cocktailDescriptor)
    let favorites = try context.fetch(favoriteDescriptor)

    guard let cocktail = cocktails.first,
          let favorite = favorites.first
    else {
      print("[ModelActor] Cocktail or Favorite not found for remove operation")
      throw NSError(domain: "CocktailModelActor", code: 404, userInfo: [NSLocalizedDescriptionKey: "Cocktail or Favorite not found"])
    }

    favorite.cocktails?.removeAll { $0.name == cocktailName }
    cocktail.favorites?.removeAll { $0.name == favoriteName }

    try context.save()
    print("[ModelActor] Removed cocktail \(cocktailName) from favorite \(favoriteName)")
  }
}
