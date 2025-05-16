import SwiftData
import SwiftUI

/// View that displays the details of a favorite cocktail list.
/// Shows all cocktails in a favorite list and allows removing cocktails from the list.
struct DetailFavoriteView: View {
  let favoriteName: String
  let modelContainer: ModelContainer
  @State private var isFetching = false
  @State private var cocktails: [CocktailDTO] = []
  @State private var favorite: FavoritesDTO? = nil
  @StateObject private var viewModel: QueryCocktailViewModel
  @State private var shouldRefresh = false
  @Environment(\.dismiss) private var dismiss

  init(favoriteName: String, modelContainer: ModelContainer) {
    self.favoriteName = favoriteName
    self.modelContainer = modelContainer
    _viewModel = StateObject(wrappedValue: QueryCocktailViewModel(modelContainer: modelContainer))
    print("[DetailView] Initialized for favorite: \(favoriteName)")
  }

  var body: some View {
    List {
      if isFetching {
        ProgressView("Loading...")
      } else if let favorite = favorite, !cocktails.isEmpty {
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
                shouldRefresh = true
                try? await refreshData()
                await checkIfFavoriteStillExists()
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
    .navigationTitle(favoriteName)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      print("[DetailView] .task (onAppear) for favorite: \(favoriteName)")
      try? await refreshData()
      await checkIfFavoriteStillExists()
    }
    .onChange(of: shouldRefresh) { _, newValue in
      if newValue {
        Task {
          try? await refreshData()
          shouldRefresh = false
          await checkIfFavoriteStillExists()
        }
      }
    }
    .onChange(of: favoriteName) { _, _ in
      Task {
        try? await refreshData()
        await checkIfFavoriteStillExists()
      }
    }
  }

  private func refreshData() async throws {
    print("[DetailView] refreshData called for favorite: \(favoriteName)")
    isFetching = true
    defer { isFetching = false }

    let fetchedFavorites = try await viewModel.backgroundFetchFavorites()
    if let updatedFavorite = fetchedFavorites.first(where: { $0.name == favoriteName }) {
      favorite = updatedFavorite
      cocktails = updatedFavorite.cocktails ?? []
      print("[DetailView] refreshData result: cocktails=\(cocktails.map { $0.name })")
    } else {
      favorite = nil
      cocktails = []
      print("[DetailView] refreshData: favorite not found")
    }
  }

  @MainActor
  private func checkIfFavoriteStillExists() async {
    let fetchedFavorites = try? await viewModel.backgroundFetchFavorites()
    let stillExists = fetchedFavorites?.contains(where: { $0.name == favoriteName }) ?? false
    if !stillExists {
      dismiss()
    }
  }
}
