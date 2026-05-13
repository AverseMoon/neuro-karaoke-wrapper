// entrypoint of injected bundle
import { invoke } from "@tauri-apps/api/core";
// @ts-ignore
import ei from "./exampleImpl";
ei;
const injectDomains = [
    "neurokaraoke.com",
    "evilkaraoke.com",
    "twinskaraoke.com",
];
async function init() {
    window.neurokaraoke.listen("player", () => {
        console.log("player state change");
    });
    window.neurokaraoke.listen("player.shuffle", () => {
        console.log("player.shuffle state change");
    });
    console.log(await invoke("greet", { name: "asdasdada" }));
}
if (injectDomains.some(d => window.location.hostname.endsWith(d)))
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", init);
    }
    else {
        init();
    }
