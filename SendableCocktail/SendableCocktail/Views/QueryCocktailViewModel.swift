import SwiftUI
import SwiftData

/// ViewModel responsible for managing cocktail queries and favorites operations.
/// Handles background fetching of cocktails and favorites, as well as managing favorite lists.
@Observable
final class QueryCocktailViewModel: Sendable {
    let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        print("[ViewModel] Initialized with modelContainer: \(modelContainer)")
    }
    
    func backgroundFetchCocktails() async throws -> [CocktailDTO] {
        print("[ViewModel] backgroundFetchCocktails called")
        let backgroundActor = CocktailModelActor(modelContainer: modelContainer)
        let result = try await backgroundActor.fetchCocktails()
        print("[ViewModel] backgroundFetchCocktails result: \(result.map { $0.name })")
        return result
    }
    
    func backgroundFetchFavorites() async throws -> [FavoritesDTO] {
        print("[ViewModel] backgroundFetchFavorites called")
        let backgroundActor = CocktailModelActor(modelContainer: modelContainer)
        let result = try await backgroundActor.fetchFavorites()
        print("[ViewModel] backgroundFetchFavorites result: \(result.map { $0.name })")
        return result
    }
    
    func addCocktailToFavorite(cocktailName: String, favoriteName: String) async throws {
        print("[ViewModel] addCocktailToFavorite called: \(cocktailName) -> \(favoriteName)")
        let backgroundActor = CocktailModelActor(modelContainer: modelContainer)
        try await backgroundActor.addCocktailToFavorite(cocktailName: cocktailName, favoriteName: favoriteName)
        print("[ViewModel] addCocktailToFavorite finished")
    }
    
    func removeCocktailFromFavorite(cocktailName: String, favoriteName: String) async throws {
        print("[ViewModel] removeCocktailFromFavorite called: \(cocktailName) from \(favoriteName)")
        let backgroundActor = CocktailModelActor(modelContainer: modelContainer)
        try await backgroundActor.removeCocktailFromFavorite(cocktailName: cocktailName, favoriteName: favoriteName)
        print("[ViewModel] removeCocktailFromFavorite finished")
    }
    
    func createNewFavorite(name: String) async throws {
        print("[ViewModel] createNewFavorite called: \(name)")
        let backgroundActor = CocktailModelActor(modelContainer: modelContainer)
        try await backgroundActor.addFavorite(name: name)
        print("[ViewModel] createNewFavorite finished")
    }
} 