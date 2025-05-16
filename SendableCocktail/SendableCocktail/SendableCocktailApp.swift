//
//  SendableCocktailApp.swift
//  SendableCocktail
//
//  Created by Sean Armstrong on 5/13/25.
//

import SwiftUI
import SwiftData

/// Main application entry point for the SendableCocktail app.
/// Initializes the SwiftData model container and sets up the main window with QueryCocktailView.
@main
struct SendableCocktailApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Cocktail.self, Favorites.self)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            QueryCocktailView(modelContainer: modelContainer)
        }
    }
}
