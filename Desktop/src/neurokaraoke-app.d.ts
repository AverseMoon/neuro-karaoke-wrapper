export {};

interface NeuroKaraokeApp {
    disable_decorations: boolean,
    devtools: boolean,
}

declare global {
    interface Window { neurokaraokeapp: NeuroKaraokeApp; }
}