import {NeuroKaraokeApp} from "./neurokaraoke-app";
import {NeuroKaraoke} from "./neurokaraoke-api";

export {};

declare global {
    interface Window {
        neurokaraokeapp: NeuroKaraokeApp;
        neurokaraoke: NeuroKaraoke;

        __TAURI__: any;
    }
}