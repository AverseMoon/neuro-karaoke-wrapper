// this file has been sent off to soul and may be implemented soon!

// example implementation i slopcoded and then manually edited cause im lazy

/**
 * @type {Record<string, (() => void)[]>}
 */
const listeners = {};

/**
 * @param {string} event
 * @param {() => void} callback
 */
function listen(event, callback) {
    if (!listeners[event]) listeners[event] = [];
    listeners[event].push(callback);
}

function splitHierarchy(input) {
    const parts = input.split(".");
    const result = [];

    for (let i = parts.length; i > 0; i--) {
        result.push(parts.slice(0, i).join("."));
    }

    return result;
}

/**
 * @param {string} event
 */
function emit(event) {
    splitHierarchy(event).forEach(s => listeners[s]?.forEach(c => c()));
}

// internal state
const state = {
    currentSong: undefined,
    currentPlaylist: undefined,

    shuffle: false,
    loop: false,
    volume: 1,
    time: 0,
    playing: false
};

const player = {
    get currentSong() {return state.currentSong;},

    get currentPlaylist() {return state.currentPlaylist;},
    get shuffle() {return state.shuffle;},
    set shuffle(value) {
        state.shuffle = !!value;
        emit("player.shuffle");
    },
    get loop() {return state.loop;},
    set loop(value) {
        state.loop = !!value;
        emit("player.loop");
    },
    get volume() {return state.volume;},
    set volume(value) {
        state.volume = Number(value);
        emit("player.volume");
    },
    get time() {return state.time;},
    set time(value) {
        state.time = Number(value);
        emit("player.time");
    },
    get playing() {return state.playing;},
    set playing(value) {
        state.playing = !!value;
        emit("player.playing");
    },
    nextSong() {
        console.log("nextSong called");
        return false;
    },
    lastSong() {
        console.log("lastSong called");
        return false;
    }
};

// public api
window.neurokaraoke = {
    player,
    listen
};