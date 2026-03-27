import AVFoundation
import Foundation
import SwiftUI

enum Singer: String, Codable {
    case neuro = "NEURO"
    case evil = "EVIL"
    case duet = "DUET"
    case other = "OTHER"

    var displayName: String {
        switch self {
        case .neuro:
            return "Neuro-sama"
        case .evil:
            return "Evil Neuro"
        case .duet:
            return "Neuro & Evil"
        case .other:
            return "Other"
        }
    }
}

struct Song: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let coverURL: URL?
    let audioURL: URL?
    let singer: Singer
    let playlistName: String?
    let artCredit: String?
}

struct Playlist: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let coverURL: URL?
    let previewCoverURLs: [URL]
    let songCount: Int
    var songs: [Song] = []
}

struct Artist: Identifiable, Hashable {
    let id: String
    let name: String
    let imageURL: URL?
    let songCount: Int
    let summary: String
}

struct CoverDistribution: Hashable {
    let totalSongs: Int
    let neuroCount: Int
    let evilCount: Int
    let duetCount: Int
    let otherCount: Int
}

struct SetupProgress {
    let fraction: Double
    let status: String
    let detail: String
}

@MainActor
final class AppModel: NSObject, ObservableObject {
    @Published private(set) var setupProgress = SetupProgress(
        fraction: 0,
        status: "Preparing…",
        detail: "Loading bundled playlist catalog"
    )
    @Published private(set) var isReady = false
    @Published private(set) var playlists: [Playlist] = []
    @Published private(set) var allSongs: [Song] = []
    @Published private(set) var artists: [Artist] = []
    @Published private(set) var trendingSongs: [Song] = []
    @Published private(set) var coverDistribution: CoverDistribution?
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published var selectedTab: AppTab = .home
    @Published var errorMessage: String?

    private let api = NeuroKaraokeAPI()
    private let player = AVPlayer()
    private var timeObserver: Any?
    private var queue: [Song] = []
    private var currentIndex = 0
    private var didStart = false

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }

    func start() async {
        guard !didStart else { return }
        didStart = true
        configurePlayerObserver()

        do {
            let seedPlaylists = try api.loadSeedPlaylists()
            await updateProgress(0.08, "Fetching playlist info…", "Resolving \(seedPlaylists.count) setlists")

            var hydratedPlaylists: [Playlist] = []
            hydratedPlaylists.reserveCapacity(seedPlaylists.count)

            for (offset, seed) in seedPlaylists.enumerated() {
                let info = try? await api.fetchPlaylistInfo(id: seed.id)
                var playlist = Playlist(
                    id: seed.id,
                    title: info?.title.isEmpty == false ? info!.title : seed.title,
                    description: info?.description ?? seed.description,
                    coverURL: info?.coverURL ?? seed.coverURL,
                    previewCoverURLs: info?.previewCoverURLs.isEmpty == false ? info!.previewCoverURLs : seed.previewCoverURLs,
                    songCount: info?.songCount ?? seed.songCount,
                    songs: []
                )

                let fraction = 0.08 + (Double(offset + 1) / Double(seedPlaylists.count)) * 0.22
                let displayTitle = playlist.title.isEmpty ? "Playlist \(offset + 1)" : playlist.title
                await updateProgress(fraction, "Fetching playlist info…", displayTitle)

                do {
                    let songs = try await api.fetchPlaylistSongs(id: seed.id)
                    playlist.songs = songs
                } catch {
                    errorMessage = "Some playlists could not be loaded."
                }

                let songsFraction = 0.30 + (Double(offset + 1) / Double(seedPlaylists.count)) * 0.55
                await updateProgress(songsFraction, "Loading songs…", displayTitle)
                hydratedPlaylists.append(playlist)
            }

            let uniqueSongs = Array(
                Dictionary(hydratedPlaylists.flatMap(\.songs).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                    .values
            )
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

            playlists = hydratedPlaylists
                .filter { !$0.songs.isEmpty || !$0.title.isEmpty }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
            allSongs = uniqueSongs

            await updateProgress(0.90, "Syncing discovery data…", "Loading artists and stats")

            async let artistsTask = api.fetchArtists()
            async let distributionTask = api.fetchCoverDistribution()
            async let trendingTask = api.fetchTrendingSongs()

            artists = (try? await artistsTask) ?? []
            coverDistribution = try? await distributionTask
            trendingSongs = (try? await trendingTask) ?? Array(uniqueSongs.prefix(8))

            await updateProgress(1.0, "Ready", "\(uniqueSongs.count) songs available")
            isReady = true
        } catch {
            errorMessage = error.localizedDescription
            isReady = true
        }
    }

    func songs(for playlist: Playlist) -> [Song] {
        playlists.first(where: { $0.id == playlist.id })?.songs ?? playlist.songs
    }

    func songs(for artist: Artist) -> [Song] {
        allSongs.filter { song in
            song.artist.localizedCaseInsensitiveContains(artist.name)
        }
    }

    func filteredSongs(query: String) -> [Song] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allSongs
        }

        let normalizedQuery = query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return allSongs.filter { song in
            song.title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(normalizedQuery) ||
            song.artist.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(normalizedQuery) ||
            (song.playlistName?.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).contains(normalizedQuery) ?? false)
        }
    }

    func play(_ song: Song, in songs: [Song]? = nil) {
        queue = songs ?? allSongs
        if let queueIndex = queue.firstIndex(of: song) {
            currentIndex = queueIndex
        } else {
            queue = [song]
            currentIndex = 0
        }

        currentSong = queue[currentIndex]
        guard let url = currentSong?.audioURL else { return }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.play()
        isPlaying = true
    }

    func togglePlayback() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    func seek(to progress: Double) {
        guard duration > 0 else { return }
        let seconds = duration * progress
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func playNext() {
        guard !queue.isEmpty else { return }
        currentIndex = min(currentIndex + 1, queue.count - 1)
        play(queue[currentIndex], in: queue)
    }

    func playPrevious() {
        guard !queue.isEmpty else { return }
        if currentTime > 5 {
            seek(to: 0)
            return
        }
        currentIndex = max(currentIndex - 1, 0)
        play(queue[currentIndex], in: queue)
    }

    private func configurePlayerObserver() {
        guard timeObserver == nil else { return }
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            currentTime = time.seconds.isFinite ? time.seconds : 0
            duration = player.currentItem?.duration.seconds.isFinite == true ? player.currentItem?.duration.seconds ?? 0 : 0
        }
    }

    private func updateProgress(_ fraction: Double, _ status: String, _ detail: String) {
        setupProgress = SetupProgress(fraction: fraction, status: status, detail: detail)
    }
}

enum AppTab: Hashable {
    case home
    case search
    case setlists
    case artists
}

private struct SeedCatalog: Decodable {
    let playlists: [SeedPlaylist]
}

private struct SeedPlaylist: Decodable {
    let id: String
    let name: String?
    let description: String?
    let coverUrl: String?
    let previewCovers: [String]?
    let songCount: Int?
}

private struct PlaylistResponse: Decodable {
    let name: String?
    let description: String?
    let cover: String?
    let songs: [PlaylistSongResponse]
}

private struct PlaylistSongResponse: Decodable {
    let title: String
    let originalArtists: String?
    let coverArtists: String?
    let coverArt: String?
    let audioUrl: String?
    let artCredit: String?
}

private struct ArtistResponse: Decodable {
    let id: String
    let name: String
    let imagePath: String?
    let songCount: Int?
    let summary: String?
}

private struct CoverDistributionResponse: Decodable {
    let totalSongs: Int
    let neuroCount: Int
    let evilCount: Int
    let duetCount: Int
    let otherCount: Int
}

private struct TrendingSongResponse: Decodable {
    struct CoverArtResponse: Decodable {
        let cloudflareId: String?
        let absolutePath: String?
    }

    let id: String?
    let title: String
    let originalArtists: [String]?
    let coverArtists: [String]?
    let coverArt: CoverArtResponse?
    let absolutePath: String?
}

private struct PlaylistInfo {
    let title: String
    let description: String
    let coverURL: URL?
    let previewCoverURLs: [URL]
    let songCount: Int
}

struct NeuroKaraokeAPI {
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 40
        return URLSession(configuration: configuration)
    }()

    private let decoder = JSONDecoder()
    private let baseURL = URL(string: "https://idk.neurokaraoke.com")!
    private let apiURL = URL(string: "https://api.neurokaraoke.com")!

    func loadSeedPlaylists() throws -> [Playlist] {
        guard let url = Bundle.main.url(forResource: "playlists", withExtension: "json") else {
            throw URLError(.fileDoesNotExist)
        }

        let data = try Data(contentsOf: url)
        let catalog = try decoder.decode(SeedCatalog.self, from: data)

        return catalog.playlists.map { seed in
            Playlist(
                id: seed.id,
                title: seed.name ?? "",
                description: seed.description ?? "",
                coverURL: URL(string: seed.coverUrl ?? ""),
                previewCoverURLs: (seed.previewCovers ?? []).compactMap(URL.init(string:)),
                songCount: seed.songCount ?? 0,
                songs: []
            )
        }
    }

    func fetchPlaylistInfo(id: String) async throws -> PlaylistInfo {
        let response: PlaylistResponse = try await fetchJSON(from: baseURL.appending(path: "/public/playlist/\(id)"))
        let previewCoverURLs = response.songs.prefix(20).compactMap { song -> URL? in
            if let explicit = absoluteMediaURL(path: song.coverArt) {
                return explicit
            }
            return song.audioUrl.flatMap(derivedCoverURL(audioPath:))
        }

        return PlaylistInfo(
            title: response.name ?? "",
            description: response.description ?? "",
            coverURL: absoluteMediaURL(path: response.cover),
            previewCoverURLs: Array(NSOrderedSet(array: previewCoverURLs)) as? [URL] ?? previewCoverURLs,
            songCount: response.songs.count
        )
    }

    func fetchPlaylistSongs(id: String) async throws -> [Song] {
        let response: PlaylistResponse = try await fetchJSON(from: baseURL.appending(path: "/public/playlist/\(id)"))
        return response.songs.enumerated().compactMap { offset, song in
            let audioURL = URL(string: song.audioUrl ?? "")
            let songID = audioURL?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "\(id)-\(offset)"
            let artists = (song.originalArtists?.isEmpty == false ? song.originalArtists : nil) ?? "Unknown Artist"

            return Song(
                id: songID,
                title: song.title,
                artist: artists,
                coverURL: absoluteMediaURL(path: song.coverArt) ?? song.audioUrl.flatMap(derivedCoverURL(audioPath:)),
                audioURL: audioURL,
                singer: singer(from: song.coverArtists),
                playlistName: response.name,
                artCredit: song.artCredit
            )
        }
    }

    func fetchArtists() async throws -> [Artist] {
        let response: [ArtistResponse] = try await fetchJSON(from: apiURL.appending(path: "/api/artists"))
        return response.map { artist in
            Artist(
                id: artist.id,
                name: artist.name,
                imageURL: absoluteMediaURL(path: artist.imagePath),
                songCount: artist.songCount ?? 0,
                summary: artist.summary ?? ""
            )
        }
        .sorted { $0.songCount > $1.songCount }
    }

    func fetchCoverDistribution() async throws -> CoverDistribution {
        let response: CoverDistributionResponse = try await fetchJSON(from: apiURL.appending(path: "/api/stats/cover-distribution"))
        return CoverDistribution(
            totalSongs: response.totalSongs,
            neuroCount: response.neuroCount,
            evilCount: response.evilCount,
            duetCount: response.duetCount,
            otherCount: response.otherCount
        )
    }

    func fetchTrendingSongs() async throws -> [Song] {
        let url = apiURL.appending(path: "/api/explore/trendings").appending(queryItems: [
            URLQueryItem(name: "days", value: "7")
        ])
        let response: [TrendingSongResponse] = try await fetchJSON(from: url)
        return response.map { item in
            Song(
                id: item.id ?? item.title,
                title: item.title,
                artist: item.originalArtists?.joined(separator: ", ").nilIfEmpty ?? "Unknown Artist",
                coverURL: trendingCoverURL(item.coverArt),
                audioURL: item.absolutePath.flatMap { URL(string: "https://storage.neurokaraoke.com/\($0)") },
                singer: singer(from: item.coverArtists?.joined(separator: ", ")),
                playlistName: "Trending",
                artCredit: nil
            )
        }
    }

    private func fetchJSON<T: Decodable>(from url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(T.self, from: data)
    }

    private func absoluteMediaURL(path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http"), let url = URL(string: path) {
            return url
        }
        if path.hasPrefix("/") {
            return URL(string: "https://storage.neurokaraoke.com\(path)")
        }
        return URL(string: "https://storage.neurokaraoke.com/\(path)")
    }

    private func derivedCoverURL(audioPath: String) -> URL? {
        let derived = audioPath
            .replacingOccurrences(of: "/audio/", with: "/images/")
            .replacingOccurrences(of: ".mp3", with: ".jpg")
        return URL(string: derived)
    }

    private func trendingCoverURL(_ coverArt: TrendingSongResponse.CoverArtResponse?) -> URL? {
        guard let coverArt else { return nil }
        if let cloudflareID = coverArt.cloudflareId, !cloudflareID.isEmpty {
            return URL(string: "https://images.neurokaraoke.com/WxURxyML82UkE7gY-PiBKw/\(cloudflareID)/public")
        }
        if let absolutePath = coverArt.absolutePath, !absolutePath.isEmpty {
            return URL(string: absolutePath)
        }
        return nil
    }

    private func singer(from coverArtists: String?) -> Singer {
        let value = coverArtists?.localizedLowercase ?? ""
        if value.contains("evil") && value.contains("neuro") {
            return .duet
        }
        if value.contains("evil") {
            return .evil
        }
        if value.isEmpty {
            return .other
        }
        return .neuro
    }
}

private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + queryItems
        return components.url ?? self
    }
}

private extension Optional where Wrapped == String {
    var nilIfEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}
