import SwiftUI
import SwiftData

/// Main view for managing cocktail favorites.
/// - Users can search for cocktails using The Cocktail DB API (with fuzzy matching).
/// - Tapping a search result presents a modal to select a favorites list and add the cocktail.
/// - Users can create new favorites lists and view/edit their contents.
struct QueryCocktailView: View {
    let modelContainer: ModelContainer
    @State private var isFetching = false
    @State private var cocktails: [CocktailDTO] = []
    @State private var favorites: [FavoritesDTO] = []
    @State private var newFavoriteName = ""
    @State private var searchQuery = ""
    @State private var searchResults: [String] = []
    @State private var isSearching = false
    @State private var showAddSheet = false
    @State private var selectedCocktailName: String? = nil
    @State private var selectedFavoriteForAdd: String? = nil
    var viewModel: QueryCocktailViewModel
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        viewModel = QueryCocktailViewModel(modelContainer: modelContainer)
        print("[View] QueryCocktailView initialized")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search field
                HStack {
                    TextField("Search cocktails...", text: $searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: searchQuery) { _, newValue in
                            Task {
                                if !newValue.isEmpty {
                                    isSearching = true
                                    do {
                                        searchResults = try await viewModel.searchCocktails(query: newValue)
                                    } catch {
                                        print("[View] Search error: \(error)")
                                        searchResults = []
                                    }
                                    isSearching = false
                                } else {
                                    searchResults = []
                                }
                            }
                        }
                }
                .padding()
                
                // Search results
                if !searchResults.isEmpty {
                    List {
                        Section("Search Results") {
                            ForEach(searchResults, id: \.self) { cocktailName in
                                Button(action: {
                                    selectedCocktailName = cocktailName
                                    selectedFavoriteForAdd = favorites.first?.name
                                    showAddSheet = true
                                }) {
                                    Text(cocktailName)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                
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
                
                if isFetching {
                    ProgressView("Loading...")
                }
                
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
            .navigationTitle("Cocktail Favorites")
            .navigationDestination(for: FavoritesDTO.self) { favorite in
                DetailFavoriteView(favorite: favorite, modelContainer: modelContainer)
            }
            .task {
                print("[View] QueryCocktailView .task (onAppear)")
                try? await refreshData()
            }
            .sheet(isPresented: $showAddSheet) {
                if let cocktailName = selectedCocktailName {
                    VStack(spacing: 20) {
                        Text("Add \(cocktailName) to a Favorites List")
                            .font(.headline)
                        Picker("Select Favorites List", selection: $selectedFavoriteForAdd) {
                            ForEach(favorites, id: \.name) { favorite in
                                Text(favorite.name).tag(favorite.name as String?)
                            }
                        }
                        .pickerStyle(.wheel)
                        Button("Add to List") {
                            if let favoriteName = selectedFavoriteForAdd {
                                Task {
                                    try? await viewModel.addCocktailToFavorite(cocktailName: cocktailName, favoriteName: favoriteName)
                                    try? await refreshData()
                                    showAddSheet = false
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Cancel", role: .cancel) {
                            showAddSheet = false
                        }
                    }
                    .padding()
                }
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