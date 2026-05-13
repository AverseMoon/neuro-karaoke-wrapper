// readonly marked fields only means we will never set them (site has full control of setting them)
// your implementation can use getters and setters

/** Playback-related things */
export interface Player {
    /** The currently playing song, or undefined */
    readonly currentSong?: Song;
    /** ID of currently playing playlist, or undefined */
    readonly currentPlaylist?: string;

    /** Whether shuffle is on or off */
    shuffle: boolean;
    /** Whether loop is on or off */
    loop: boolean;
    /** Volume */
    volume: number;
    /** Seconds since the start of the song */
    time: number
    /** Is there a song playing? */
    playing: boolean;

    /**
     * Goes forward a song
     *  @returns success
     */
    nextSong(): boolean;
    /**
     * Goes backward a song
     * @returns success
     */
    lastSong(): boolean;
}

export interface NeuroKaraoke {
    readonly player: Player;
    /**
     * Register an event listener
     * @param event the event to listen to (eg. `player.volume`, `player`, `player.loop`, etc...)
     * @param callback the function called when the event is fired
     */
    // events should be fired when a value is set, either by an external script, or by the site, with a name corresponding to what was set (eg. `player.volume`, `player`, `player.loop`, etc...)
    // impl note: when emitting an event, you need to also emit all parents of that event (eg. 'player.volume' -> emit('player.volume') and emit('player'))
    listen(event: string, callback: () => void): void;
}

// you can skim through everything after this comment and yell at me for not getting the api types right lol
//----------------------------------------------------
// stripped down versions of things u get from api calls
// good enough for my purpose atm

export type Song = {
    id: string;
    title: string;
    duration: number;
    coverArtists: string[];
    originalArtists: string[];
    coverArt: Art;
    userUploaded: boolean;
};

export type Art = {
    id: string;
    fileName: string;
    contentType: string;

    description: string | null;
    credit: string | null;

    cloudflareId: string;
    mediaStorageType: number;
    absolutePath: string;

    artist: Artist;

    upvotes: number;
    tagString: string;
    mediaTag: number;
};

export type Artist = {
    id: string;
    name: string;
    socialLink: string | null;
    userId: string | null;
};

// add to global `window` type
declare global {
    interface Window { neurokaraoke: NeuroKaraoke; }
}