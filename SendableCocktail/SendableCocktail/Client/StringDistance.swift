import Foundation

/// Utility for calculating string distances and finding near matches.
/// Used for fuzzy searching cocktail names (Levenshtein distance) in The Cocktail DB client.
struct StringDistance {
    /// Calculate the Levenshtein distance between two strings
    static func levenshtein(_ s1: String, _ s2: String) -> Int {
        let s1 = s1.lowercased()
        let s2 = s2.lowercased()
        
        let empty = Array(repeating: 0, count: s2.count + 1)
        var last = Array(0...s2.count)
        
        for (i, t_char) in s1.enumerated() {
            var current = [i + 1] + empty
            for (j, s_char) in s2.enumerated() {
                current[j + 1] = t_char == s_char ? last[j] : min(last[j], last[j + 1], current[j]) + 1
            }
            last = current
        }
        return last[s2.count]
    }
    
    /// Find near matches in an array of strings based on Levenshtein distance
    /// - Parameters:
    ///   - query: The search query
    ///   - candidates: Array of strings to search through
    ///   - maxDistance: Maximum allowed Levenshtein distance (default: 3)
    /// - Returns: Array of strings that are within the maximum distance
    static func findNearMatches(query: String, candidates: [String], maxDistance: Int = 3) -> [String] {
        candidates.filter { candidate in
            levenshtein(query, candidate) <= maxDistance
        }
    }
} 