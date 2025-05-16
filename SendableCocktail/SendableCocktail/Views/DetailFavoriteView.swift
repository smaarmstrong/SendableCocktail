import SwiftData
import SwiftUI

/// View that displays the details of a favorite cocktail list.
/// Shows all cocktails in a favorite list and allows removing cocktails from the list.
struct DetailFavoriteView: View {
  let favorite: FavoritesDTO
  let modelContainer: ModelContainer
  @State private var isFetching = false
  @State private var cocktails: [CocktailDTO] = []
  var viewModel: QueryCocktailViewModel

  init(favorite: FavoritesDTO, modelContainer: ModelContainer) {
    self.favorite = favorite
    self.modelContainer = modelContainer
    viewModel = QueryCocktailViewModel(modelContainer: modelContainer)
    print("[DetailView] Initialized for favorite: \(favorite.name)")
  }

  var body: some View {
    List {
      if isFetching {
        ProgressView("Loading...")
      } else if !cocktails.isEmpty {
        ForEach(cocktails, id: \.name) { cocktail in
          HStack {
            Text(cocktail.name)
              .font(.headline)
            Spacer()
            Button(role: .destructive) {
              print("[DetailView] Remove cocktail button tapped: \(cocktail.name) from \(favorite.name)")
              Task {
                try? await viewModel.removeCocktailFromFavorite(
                  cocktailName: cocktail.name,
                  favoriteName: favorite.name
                )
                try? await refreshData()
              }
            } label: {
              Image(systemName: "minus.circle.fill")
                .foregroundStyle(.red)
            }
          }
        }
      } else {
        ContentUnavailableView("No Cocktails", systemImage: "wineglass")
      }
    }
    .navigationTitle(favorite.name)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      print("[DetailView] .task (onAppear) for favorite: \(favorite.name)")
      if cocktails.isEmpty {
        cocktails = favorite.cocktails ?? []
      }
      try? await refreshData()
    }
  }

  private func refreshData() async throws {
    print("[DetailView] refreshData called for favorite: \(favorite.name)")
    isFetching = true
    defer { isFetching = false }

    let fetchedFavorites = try await viewModel.backgroundFetchFavorites()
    if let updatedFavorite = fetchedFavorites.first(where: { $0.name == favorite.name }) {
      cocktails = updatedFavorite.cocktails ?? []
      print("[DetailView] refreshData result: cocktails=\(cocktails.map { $0.name })")
    } else {
      print("[DetailView] refreshData: favorite not found")
    }
  }
}
