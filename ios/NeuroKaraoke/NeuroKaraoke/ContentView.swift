import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()
    @State private var selectedSong: Song?
    @State private var searchText = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            themeBackground
                .ignoresSafeArea()

            if model.isReady {
                TabView(selection: $model.selectedTab) {
                    NavigationStack {
                        HomeTab(model: model, selectedSong: $selectedSong)
                    }
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(AppTab.home)

                    NavigationStack {
                        SearchTab(model: model, selectedSong: $selectedSong, searchText: $searchText)
                    }
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(AppTab.search)

                    NavigationStack {
                        SetlistsTab(model: model, selectedSong: $selectedSong)
                    }
                    .tabItem {
                        Label("Setlists", systemImage: "music.note.list")
                    }
                    .tag(AppTab.setlists)

                    NavigationStack {
                        ArtistsTab(model: model, selectedSong: $selectedSong)
                    }
                    .tabItem {
                        Label("Artists", systemImage: "person.3.fill")
                    }
                    .tag(AppTab.artists)
                }
                .tint(theme.primary)

                if let currentSong = model.currentSong {
                    MiniPlayer(song: currentSong, model: model)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 88)
                        .onTapGesture {
                            selectedSong = currentSong
                        }
                }
            } else {
                SetupView(progress: model.setupProgress, errorMessage: model.errorMessage)
            }
        }
        .task {
            await model.start()
        }
        .sheet(item: $selectedSong) { song in
            PlayerView(song: song, model: model)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var theme: AppTheme {
        AppTheme.forSinger(model.currentSong?.singer)
    }

    private var themeBackground: some View {
        LinearGradient(
            colors: [theme.backgroundTop, theme.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(theme.primary.opacity(0.18))
                .frame(width: 220, height: 220)
                .blur(radius: 12)
                .offset(x: 80, y: -20)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(theme.secondary.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 18)
                .offset(x: -80, y: 80)
        }
    }
}

private struct HomeTab: View {
    @ObservedObject var model: AppModel
    @Binding var selectedSong: Song?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeroCard(
                    latestPlaylist: model.playlists.first,
                    distribution: model.coverDistribution
                )

                if !model.trendingSongs.isEmpty {
                    sectionHeader("Trending This Week")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(model.trendingSongs.prefix(8)) { song in
                                SongPoster(song: song)
                                    .frame(width: 150)
                                    .onTapGesture {
                                        model.play(song, in: model.trendingSongs)
                                        selectedSong = song
                                    }
                            }
                        }
                    }
                }

                if let latestPlaylist = model.playlists.first {
                    sectionHeader(latestPlaylist.title.isEmpty ? "Latest Setlist" : latestPlaylist.title)
                    VStack(spacing: 10) {
                        ForEach(model.songs(for: latestPlaylist).prefix(6)) { song in
                            SongRow(song: song) {
                                model.play(song, in: model.songs(for: latestPlaylist))
                                selectedSong = song
                            }
                        }
                    }
                }

                if let distribution = model.coverDistribution {
                    sectionHeader("Cover Distribution")
                    DistributionCard(distribution: distribution)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 140)
        }
        .navigationTitle("Neuro Karaoke")
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
        }
    }
}

private struct SearchTab: View {
    @ObservedObject var model: AppModel
    @Binding var selectedSong: Song?
    @Binding var searchText: String

    var body: some View {
        let results = model.filteredSongs(query: searchText)

        List(results) { song in
            SongRow(song: song) {
                model.play(song, in: results)
                selectedSong = song
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .searchable(text: $searchText, prompt: "Search songs, artists, playlists")
        .navigationTitle("Search")
    }
}

private struct SetlistsTab: View {
    @ObservedObject var model: AppModel
    @Binding var selectedSong: Song?

    var body: some View {
        List(model.playlists) { playlist in
            NavigationLink(value: playlist) {
                PlaylistRow(playlist: playlist)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("Setlists")
        .navigationDestination(for: Playlist.self) { playlist in
            PlaylistDetailView(playlist: playlist, model: model, selectedSong: $selectedSong)
        }
    }
}

private struct ArtistsTab: View {
    @ObservedObject var model: AppModel
    @Binding var selectedSong: Song?

    var body: some View {
        List(model.artists) { artist in
            NavigationLink(value: artist) {
                ArtistRow(artist: artist)
            }
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationTitle("Artists")
        .navigationDestination(for: Artist.self) { artist in
            ArtistDetailView(artist: artist, model: model, selectedSong: $selectedSong)
        }
    }
}

private struct PlaylistDetailView: View {
    let playlist: Playlist
    @ObservedObject var model: AppModel
    @Binding var selectedSong: Song?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BannerArtwork(imageURL: playlist.coverURL ?? playlist.previewCoverURLs.first)
                    .frame(height: 220)

                Text(playlist.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                if !playlist.description.isEmpty {
                    Text(playlist.description)
                        .foregroundStyle(.white.opacity(0.75))
                }

                Text("\(model.songs(for: playlist).count) songs")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.65))

                VStack(spacing: 10) {
                    ForEach(model.songs(for: playlist)) { song in
                        SongRow(song: song) {
                            let queue = model.songs(for: playlist)
                            model.play(song, in: queue)
                            selectedSong = song
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 130)
        }
        .navigationTitle("Setlist")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ArtistDetailView: View {
    let artist: Artist
    @ObservedObject var model: AppModel
    @Binding var selectedSong: Song?

    var body: some View {
        let songs = model.songs(for: artist)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BannerArtwork(imageURL: artist.imageURL)
                    .frame(height: 220)

                Text(artist.name)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                if !artist.summary.isEmpty {
                    Text(artist.summary)
                        .foregroundStyle(.white.opacity(0.78))
                }

                Text("\(songs.count) matching songs")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.65))

                VStack(spacing: 10) {
                    ForEach(songs) { song in
                        SongRow(song: song) {
                            model.play(song, in: songs)
                            selectedSong = song
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 130)
        }
        .navigationTitle("Artist")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SetupView: View {
    let progress: SetupProgress
    let errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            if let image = UIImage(named: "NeuroLogo") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .cyan.opacity(0.4), radius: 24)
            }

            Text("Neuro Karaoke")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(progress.status)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.88))

            Text(progress.detail)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)

            ProgressView(value: progress.fraction)
                .tint(.cyan)
                .scaleEffect(x: 1, y: 1.8, anchor: .center)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.pink.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
    }
}

private struct HeroCard: View {
    let latestPlaylist: Playlist?
    let distribution: CoverDistribution?

    var body: some View {
        let theme = AppTheme.forSinger(nil)

        VStack(alignment: .leading, spacing: 18) {
            Text("Cross-platform karaoke player for neurokaraoke.com")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if let latestPlaylist {
                HStack(spacing: 14) {
                    BannerArtwork(imageURL: latestPlaylist.coverURL ?? latestPlaylist.previewCoverURLs.first)
                        .frame(width: 86, height: 86)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Featured Setlist")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(latestPlaylist.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(latestPlaylist.songCount) songs")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Spacer()
                }
            }

            if let distribution {
                HStack {
                    Text("\(distribution.totalSongs) covers")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                    Spacer()
                    Label("Neuro \(distribution.neuroCount)", systemImage: "waveform")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(theme.primary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.55))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [theme.primary.opacity(0.7), theme.secondary.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
        )
    }
}

private struct DistributionCard: View {
    let distribution: CoverDistribution

    var body: some View {
        VStack(spacing: 12) {
            DistributionBar(title: "Neuro", value: distribution.neuroCount, total: distribution.totalSongs, color: .cyan)
            DistributionBar(title: "Evil", value: distribution.evilCount, total: distribution.totalSongs, color: .pink)
            DistributionBar(title: "Duet", value: distribution.duetCount, total: distribution.totalSongs, color: .purple)
            DistributionBar(title: "Other", value: distribution.otherCount, total: distribution.totalSongs, color: .gray)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.48))
        )
    }
}

private struct DistributionBar: View {
    let title: String
    let value: Int
    let total: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(value)")
                    .foregroundStyle(.white.opacity(0.72))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.gradient)
                        .frame(width: max(16, geometry.size.width * CGFloat(Double(value) / Double(max(total, 1)))))
                }
            }
            .frame(height: 12)
        }
    }
}

private struct SongPoster: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            BannerArtwork(imageURL: song.coverURL)
                .frame(width: 150, height: 150)
            Text(song.title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
            Text(song.artist)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .lineLimit(1)
        }
    }
}

private struct SongRow: View {
    let song: Song
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                BannerArtwork(imageURL: song.coverURL)
                    .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.68))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let playlistName = song.playlistName {
                        Text(playlistName)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Image(systemName: "play.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.forSinger(song.singer).primary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.42))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 14) {
            BannerArtwork(imageURL: playlist.coverURL ?? playlist.previewCoverURLs.first)
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.title.isEmpty ? "Untitled Playlist" : playlist.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(playlist.songCount) songs")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.66))
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct ArtistRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 14) {
            BannerArtwork(imageURL: artist.imageURL)
                .frame(width: 72, height: 72)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(artist.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(artist.songCount) songs")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.66))
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct MiniPlayer: View {
    let song: Song
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(spacing: 12) {
            BannerArtwork(imageURL: song.coverURL)
                .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(1)
            }
            Spacer()
            Button {
                model.playPrevious()
            } label: {
                Image(systemName: "backward.fill")
                    .foregroundStyle(.white)
            }
            Button {
                model.togglePlayback()
            } label: {
                Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                    .foregroundStyle(.black)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(.white))
            }
            Button {
                model.playNext()
            } label: {
                Image(systemName: "forward.fill")
                    .foregroundStyle(.white)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.black.opacity(0.42))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                }
        )
    }
}

private struct PlayerView: View {
    let song: Song
    @ObservedObject var model: AppModel

    var body: some View {
        let activeSong = model.currentSong ?? song
        let theme = AppTheme.forSinger(activeSong.singer)

        ZStack {
            LinearGradient(colors: [theme.backgroundTop, theme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(width: 48, height: 5)
                    .padding(.top, 8)

                BannerArtwork(imageURL: activeSong.coverURL)
                    .frame(maxWidth: 320, maxHeight: 320)
                    .shadow(color: theme.primary.opacity(0.35), radius: 30)

                VStack(spacing: 8) {
                    Text(activeSong.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(activeSong.artist)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.7))
                }

                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { model.duration > 0 ? model.currentTime / model.duration : 0 },
                            set: { model.seek(to: $0) }
                        )
                    )
                    .tint(theme.primary)

                    HStack {
                        Text(formatTime(model.currentTime))
                        Spacer()
                        Text(formatTime(model.duration))
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                }

                HStack(spacing: 28) {
                    Button(action: model.playPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                    }
                    Button(action: model.togglePlayback) {
                        Image(systemName: model.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                    }
                    Button(action: model.playNext) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                    }
                }
                .foregroundStyle(.white)

                if let artCredit = activeSong.artCredit, !artCredit.isEmpty {
                    Text("Art: \(artCredit)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            if model.currentSong == nil {
                model.play(song)
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "0:00" }
        let total = Int(seconds.rounded(.down))
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }
}

private struct BannerArtwork: View {
    let imageURL: URL?

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(colors: [.cyan.opacity(0.6), .pink.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "music.note")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

private struct AppTheme {
    let primary: Color
    let secondary: Color
    let backgroundTop: Color
    let backgroundBottom: Color

    static func forSinger(_ singer: Singer?) -> AppTheme {
        switch singer {
        case .evil:
            return AppTheme(
                primary: Color(red: 0.91, green: 0.12, blue: 0.55),
                secondary: Color(red: 0.62, green: 0.15, blue: 0.69),
                backgroundTop: Color(red: 0.11, green: 0.05, blue: 0.09),
                backgroundBottom: Color(red: 0.23, green: 0.08, blue: 0.15)
            )
        case .duet:
            return AppTheme(
                primary: Color(red: 0.61, green: 0.37, blue: 0.83),
                secondary: Color(red: 0.70, green: 0.53, blue: 0.91),
                backgroundTop: Color(red: 0.07, green: 0.05, blue: 0.12),
                backgroundBottom: Color(red: 0.17, green: 0.12, blue: 0.24)
            )
        default:
            return AppTheme(
                primary: Color(red: 0.00, green: 0.85, blue: 1.00),
                secondary: Color(red: 0.00, green: 0.60, blue: 0.80),
                backgroundTop: Color(red: 0.07, green: 0.08, blue: 0.11),
                backgroundBottom: Color(red: 0.12, green: 0.14, blue: 0.19)
            )
        }
    }
}

#Preview {
    ContentView()
}
