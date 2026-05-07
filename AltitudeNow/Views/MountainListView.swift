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

private enum MountainData {
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
}

// MARK: - MountainListView

struct MountainListView: View {
    /// Called when the user taps a mountain row.
    /// Parameters: (sessionName: String, referenceAltitudeMeters: Int)
    var onSelect: (String, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var searchText  = ""
    @State private var regionFilter = String(localized: "japan_mountains_region_all")

    private var allRegions: [String] {
        [String(localized: "japan_mountains_region_all")] + MountainData.regions
    }

    private var filtered: [Mountain] {
        let allLabel = String(localized: "japan_mountains_region_all")
        return MountainData.all.filter { m in
            let regionMatch = regionFilter == allLabel || m.region == regionFilter
            let searchMatch = searchText.isEmpty
                || m.name_ja.localizedCaseInsensitiveContains(searchText)
                || m.name_en.localizedCaseInsensitiveContains(searchText)
                || m.prefecture.localizedCaseInsensitiveContains(searchText)
            return regionMatch && searchMatch
        }
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
            } else if filtered.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(filtered) { mountain in
                    mountainRow(mountain)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(mountain.name_ja, mountain.elevation_m)
                            dismiss()
                        }
                }
                .listStyle(.plain)
            }
        }
    }

    private func mountainRow(_ m: Mountain) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(m.name_ja)
                    .font(.headline)
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
