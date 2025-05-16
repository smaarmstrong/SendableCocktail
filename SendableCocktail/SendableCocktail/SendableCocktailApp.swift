//
//  SendableCocktailApp.swift
//  SendableCocktail
//
//  Created by Sean Armstrong on 5/13/25.
//

import SwiftData
import SwiftUI

/// Main application entry point for the SendableCocktail app.
/// Initializes the SwiftData model container and sets up the main window with QueryCocktailView.
@main
struct SendableCocktailApp: App {
  static let modelContainer: ModelContainer = {
    do {
      let container = try ModelContainer(for: Cocktail.self, Favorites.self, User.self)

      // Create initial users if they don't exist
      Task {
        let actor = CocktailModelActor(modelContainer: container)
        let users = try await actor.fetchUsers()

        if users.isEmpty {
          try await actor.createUser(name: "User1")
          try await actor.createUser(name: "User2")
        }
      }

      return container
    } catch {
      fatalError("Could not initialize ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      QueryCocktailView(modelContainer: Self.modelContainer)
    }
  }
}
