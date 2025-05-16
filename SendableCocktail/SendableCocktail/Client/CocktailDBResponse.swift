import Foundation

struct CocktailDBResponse: Codable {
    let drinks: [CocktailDBDrink]?
}

struct CocktailDBDrink: Codable {
    let strDrink: String
} 