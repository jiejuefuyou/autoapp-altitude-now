import SwiftUI

// MARK: - Mountain Model

struct Mountain: Identifiable, Codable {
    let id: Int
    let name_ja: String
    let name_en: String
    let elevation_m: Int
    let region: String
    let prefecture: String

    enum CodingKeys: String, CodingKey {
        case id, name_ja, name_en, elevation_m, region, prefecture
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = (try? c.decode(Int.self,    forKey: .id))          ?? 0
        name_ja     = (try? c.decode(String.self, forKey: .name_ja))     ?? ""
        name_en     = (try? c.decode(String.self, forKey: .name_en))     ?? ""
        elevation_m = (try? c.decode(Int.self,    forKey: .elevation_m)) ?? 0
        region      = (try? c.decode(String.self, forKey: .region))      ?? ""
        prefecture  = (try? c.decode(String.self, forKey: .prefecture))  ?? ""
    }
}

// MARK: - Mountain Data

enum MountainData {
    static let all: [Mountain] = {
        guard
            let url  = Bundle.main.url(forResource: "JapanMountains", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let list = try? JSONDecoder().decode([Mountain].self, from: data)
        else {
            return []
        }
        return list.sorted { $0.id < $1.id }
    }()

    static var regions: [String] {
        var seen = Set<String>()
        return all.compactMap { m in
            guard !seen.contains(m.region) else { return nil }
            seen.insert(m.region)
            return m.region
        }
    }

    /// Look up a mountain by its integer ID. Returns `nil` if missing
    /// (e.g. the user upgraded from a build with a different dataset).
    static func mountain(for id: Int) -> Mountain? {
        all.first { $0.id == id }
    }
}

/// Read/write the user's favorited mountain IDs through `@AppStorage`.
/// Stored as a comma-separated list of integers in `UserDefaults` to avoid
/// the array-encoding limitations of `@AppStorage`.
enum FavoriteMountains {
    static let storageKey = "favoritedMountainIDs"
    static let maxQuickSwitch = 3

    static func decode(_ raw: String) -> [Int] {
        raw
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }

    static func encode(_ ids: [Int]) -> String {
        ids.map(String.init).joined(separator: ",")
    }

    /// Toggle membership and return the new ordered list. Newly-added IDs
    /// are appended to the end so the user keeps their preferred ordering.
    static func toggled(_ id: Int, in current: [Int]) -> [Int] {
        if let idx = current.firstIndex(of: id) {
            var next = current
            next.remove(at: idx)
            return next
        }
        return current + [id]
    }
}

// MARK: - MountainListView

struct MountainListView: View {
    /// Called when the user taps a mountain row.
    /// Parameters: (sessionName: String, referenceAltitudeMeters: Int)
    var onSelect: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @AppStorage(FavoriteMountains.storageKey) private var favoritedRaw: String = ""

    @State private var searchText  = ""
    @State private var regionFilter = String(localized: "japan_mountains_region_all")

    private var favoriteIDs: [Int] { FavoriteMountains.decode(favoritedRaw) }

    private var favoriteMountains: [Mountain] {
        favoriteIDs.compactMap { MountainData.mountain(for: $0) }
    }

    private var allRegions: [String] {
        [String(localized: "japan_mountains_region_all")] + MountainData.regions
    }

    private var filtered: [Mountain] {
        let allLabel = String(localized: "japan_mountains_region_all")
        let favoriteSet = Set(favoriteIDs)
        return MountainData.all.filter { m in
            let regionMatch = regionFilter == allLabel || m.region == regionFilter
            let searchMatch = searchText.isEmpty
                || m.name_ja.localizedCaseInsensitiveContains(searchText)
                || m.name_en.localizedCaseInsensitiveContains(searchText)
                || m.prefecture.localizedCaseInsensitiveContains(searchText)
            // Hide favorites from the main list — they have their own section
            // when there's no active search/filter.
            let inFavoriteSection = searchText.isEmpty
                && regionFilter == allLabel
                && favoriteSet.contains(m.id)
            return regionMatch && searchMatch && !inFavoriteSection
        }
    }

    private var showFavoriteSection: Bool {
        !favoriteMountains.isEmpty
            && searchText.isEmpty
            && regionFilter == String(localized: "japan_mountains_region_all")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                regionPicker
                mountainList
            }
            .navigationTitle(String(localized: "japan_mountains_nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: String(localized: "japan_mountains_search_placeholder")
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var regionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allRegions, id: \.self) { region in
                    Button {
                        regionFilter = region
                    } label: {
                        Text(region)
                            .font(.subheadline.weight(regionFilter == region ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                regionFilter == region
                                    ? Color.accentColor
                                    : Color(.systemGray5),
                                in: Capsule()
                            )
                            .foregroundStyle(regionFilter == region ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var mountainList: some View {
        Group {
            if MountainData.all.isEmpty {
                ContentUnavailableView(
                    String(localized: "japan_mountains_load_error"),
                    systemImage: "exclamationmark.triangle"
                )
            } else if filtered.isEmpty && !showFavoriteSection {
                ContentUnavailableView.search(text: searchText)
            } else {
                List {
                    if showFavoriteSection {
                        Section {
                            ForEach(favoriteMountains) { mountain in
                                mountainRow(mountain, isFavorite: true)
                                    .contentShape(Rectangle())
                                    .onTapGesture { handleSelect(mountain) }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            toggleFavorite(mountain.id)
                                        } label: {
                                            Label(
                                                LocalizedStringKey("Unfavorite"),
                                                systemImage: "star.slash"
                                            )
                                        }
                                        .tint(.orange)
                                    }
                            }
                            .onMove(perform: moveFavorites)
                        } header: {
                            HStack {
                                Text(LocalizedStringKey("Favorites"))
                                Spacer()
                                EditButton().font(.caption)
                            }
                        }
                    }
                    Section {
                        ForEach(filtered) { mountain in
                            mountainRow(mountain, isFavorite: false)
                                .contentShape(Rectangle())
                                .onTapGesture { handleSelect(mountain) }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        toggleFavorite(mountain.id)
                                    } label: {
                                        Label(
                                            LocalizedStringKey("Favorite"),
                                            systemImage: "star.fill"
                                        )
                                    }
                                    .tint(.yellow)
                                }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func handleSelect(_ m: Mountain) {
        // Persist for Calibration auto-fill in SettingsView
        UserDefaults.standard.set(Double(m.elevation_m), forKey: "altitudenow.lastMountain.elevation")
        UserDefaults.standard.set(m.name_ja, forKey: "altitudenow.lastMountain.name")
        onSelect(m.name_ja, m.elevation_m)
        dismiss()
    }

    private func toggleFavorite(_ id: Int) {
        let next = FavoriteMountains.toggled(id, in: favoriteIDs)
        favoritedRaw = FavoriteMountains.encode(next)
    }

    private func moveFavorites(from source: IndexSet, to destination: Int) {
        var next = favoriteIDs
        next.move(fromOffsets: source, toOffset: destination)
        favoritedRaw = FavoriteMountains.encode(next)
    }

    private func mountainRow(_ m: Mountain, isFavorite: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if isFavorite {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                    }
                    Text(m.name_ja).font(.headline)
                }
                Text(m.name_en)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(m.prefecture)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(m.elevation_m) m")
                    .font(.callout.monospacedDigit().weight(.semibold))
                Text(m.region)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    MountainListView { name, alt in
        print("Selected: \(name) at \(alt)m")
    }
}
