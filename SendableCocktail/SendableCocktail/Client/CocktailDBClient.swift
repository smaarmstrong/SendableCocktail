import Foundation

/// Client for interacting with The Cocktail DB API.
/// - Supports searching for cocktails by name (with fuzzy/Levenshtein matching for near matches).
/// - Caches cocktail names to improve fuzzy search results.
actor CocktailDBClient {
  private let baseURL = "https://www.thecocktaildb.com/api/json/v1/1"
  private var cachedResults: [String] = []
  private let stringDistance = StringDistance()

  func searchCocktails(query: String) async throws -> [String] {
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let url = URL(string: "\(baseURL)/search.php?s=\(encodedQuery)")!

    let (data, _) = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(CocktailDBResponse.self, from: data)

    // Get exact matches from API
    let exactMatches = response.drinks?.map { $0.strDrink } ?? []

    // If we have cached results, also look for fuzzy matches
    if !cachedResults.isEmpty {
      let fuzzyMatches = await stringDistance.findNearMatches(
        query: query,
        candidates: cachedResults.filter { !exactMatches.contains($0) }
      )

      // Combine exact and fuzzy matches, removing duplicates
      let allMatches = Set(exactMatches + fuzzyMatches)
      return Array(allMatches).sorted()
    }

    // Update cache with new results
    cachedResults = exactMatches
    return exactMatches
  }

  /// Fetch all cocktails to populate the cache
  func populateCache() async throws {
    let url = URL(string: "\(baseURL)/list.php?c=list")!
    let (data, _) = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(CocktailDBResponse.self, from: data)
    cachedResults = response.drinks?.map { $0.strDrink } ?? []
  }
}
