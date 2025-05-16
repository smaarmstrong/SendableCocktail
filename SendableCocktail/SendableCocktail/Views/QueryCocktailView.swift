import SwiftUI
import SwiftData

/// Main view for managing cocktail favorites.
/// Allows creating new favorite lists, adding cocktails to favorites, and viewing favorite lists.
struct QueryCocktailView: View {
    let modelContainer: ModelContainer
    @State private var isFetching = false
    @State private var cocktails: [CocktailDTO] = []
    @State private var favorites: [FavoritesDTO] = []
    @State private var newFavoriteName = ""
    @State private var selectedFavorite: String?
    var viewModel: QueryCocktailViewModel
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        viewModel = QueryCocktailViewModel(modelContainer: modelContainer)
        print("[View] QueryCocktailView initialized")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Create new favorites list
                HStack {
                    TextField("New favorites list name", text: $newFavoriteName)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Create") {
                        print("[View] Create button tapped with name: \(newFavoriteName)")
                        guard !newFavoriteName.isEmpty else { return }
                        Task {
                            try await viewModel.createNewFavorite(name: newFavoriteName)
                            newFavoriteName = ""
                            try await refreshData()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                // Favorites list picker
                if !favorites.isEmpty {
                    Picker("Select Favorites List", selection: $selectedFavorite) {
                        Text("Select a list").tag(nil as String?)
                        ForEach(favorites, id: \.name) { favorite in
                            Text(favorite.name).tag(favorite.name as String?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                }
                
                // Cocktail buttons
                if let selectedFavorite = selectedFavorite {
                    VStack(spacing: 20) {
                        Text("Add to \(selectedFavorite)")
                            .font(.headline)
                        
                        ForEach(["Mojito", "Margarita", "Old Fashioned"], id: \.self) { cocktailName in
                            Button(cocktailName) {
                                print("[View] Add cocktail button tapped: \(cocktailName) to \(selectedFavorite)")
                                Task {
                                    try await viewModel.addCocktailToFavorite(
                                        cocktailName: cocktailName,
                                        favoriteName: selectedFavorite
                                    )
                                    try await refreshData()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
                
                // Refresh button
                Button("Refresh Data") {
                    print("[View] Refresh button tapped")
                    Task {
                        try await refreshData()
                    }
                }
                .buttonStyle(.bordered)
                .padding()
                
                if isFetching {
                    ProgressView("Loading...")
                } else {
                    if favorites.isEmpty {
                        ContentUnavailableView("No Favorites Lists", systemImage: "star.slash")
                    } else {
                        List {
                            ForEach(favorites, id: \.name) { favorite in
                                NavigationLink(value: favorite) {
                                    VStack(alignment: .leading) {
                                        Text(favorite.name)
                                            .font(.headline)
                                        if let cocktails = favorite.cocktails, !cocktails.isEmpty {
                                            Text("Cocktails: \(cocktails.map { $0.name }.joined(separator: ", "))")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Cocktail Favorites")
            .navigationDestination(for: FavoritesDTO.self) { favorite in
                DetailFavoriteView(favorite: favorite, modelContainer: modelContainer)
            }
            .task {
                print("[View] QueryCocktailView .task (onAppear)")
                try? await refreshData()
            }
        }
    }
    
    private func refreshData() async throws {
        print("[View] refreshData called")
        isFetching = true
        defer { isFetching = false }
        
        async let cocktailsTask = viewModel.backgroundFetchCocktails()
        async let favoritesTask = viewModel.backgroundFetchFavorites()
        
        let (fetchedCocktails, fetchedFavorites) = try await (cocktailsTask, favoritesTask)
        print("[View] refreshData result: cocktails=\(fetchedCocktails.map { $0.name }), favorites=\(fetchedFavorites.map { $0.name })")
        cocktails = fetchedCocktails
        favorites = fetchedFavorites
    }
} 