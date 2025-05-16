import SwiftUI
import SwiftData

/// ViewModel responsible for managing cocktail queries and favorites operations.
/// - Handles searching for cocktails (with fuzzy matching) using The Cocktail DB API.
/// - Presents search results for user selection and manages adding cocktails to favorites lists.
/// - Handles background fetching and CRUD operations for cocktails and favorites.
final class QueryCocktailViewModel: Sendable {
    let modelContainer: ModelContainer
    private let cocktailDBClient: CocktailDBClient
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.cocktailDBClient = CocktailDBClient()
        print("[ViewModel] Initialized with modelContainer: \(modelContainer)")
        
        // Populate the cache in the background
        Task {
            do {
                try await cocktailDBClient.populateCache()
                print("[ViewModel] Cache populated successfully")
            } catch {
                print("[ViewModel] Failed to populate cache: \(error)")
            }
        }
    }
    
    func searchCocktails(query: String) async throws -> [String] {
        print("[ViewModel] searchCocktails called with query: \(query)")
        return try await cocktailDBClient.searchCocktails(query: query)
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