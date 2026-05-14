import {invoke} from "@tauri-apps/api/core";
import {getCurrentWindow} from "@tauri-apps/api/window"
import splash from "./splash";


// only ran on neurokaraoke.com
export default async function() {
    splash();

    let border = document.createElement("div");

    border.id = "tauri-window-border";
    border.className = "theme-border";

    document.body.prepend(border);

    let controls: HTMLDivElement;

    if (!window.neurokaraokeapp.args.disable_custom_controls) {
        controls = document.createElement("div");

        controls.id = "tauri-window-controls";
        controls.className = "theme-bg-secondary theme-border";
        controls.innerHTML = `
            <div id="tauri-drag-btn" data-tauri-drag-region style="position: absolute; inset: 0;"></div>
            <div style="width: 30px"></div>
            <button id="tauri-min-btn" class="theme-primary tauri-button" onclick="window.__TAURI__.window.getCurrentWindow().minimize()">&minus;</button>
            <button id="tauri-max-btn" class="theme-primary tauri-button" onclick="window.__TAURI__.window.getCurrentWindow().toggleMaximize()">&#9633;</button>
            <button id="tauri-close-btn" class="theme-primary tauri-button" onclick="window.__TAURI__.window.getCurrentWindow().close()">&#10005;</button>
        `;

        document.body.prepend(controls);
        requestAnimationFrame(() => {
            controls.style.transform = `translate(${controls.offsetWidth}px, -${controls.offsetHeight}px)`;
            controls.classList.add("tauri-ready");
        });

        let timeout: number | null = null;
        window.addEventListener("mousemove", (ev) => {
            if (
                ev.x > window.innerWidth - controls.offsetWidth &&
                ev.y < controls.offsetHeight
            ) {
                if (timeout === null) timeout = setTimeout(
                    () => controls.classList.add("tauri-show-controls"),
                    // change delay based on if chat window is open (so you have time to click close on it if that is your real intention)
                    document.getElementById("rc-panel")?.classList.contains("rc-panel-open") ? 1800 : 0
                );
            } else {
                if (timeout !== null) {
                    clearTimeout(timeout);
                    timeout = null;
                }
                controls.classList.remove("tauri-show-controls");
            }
        });
    }

    await getCurrentWindow().onFocusChanged(({payload}) => {
        border.classList.toggle("tauri-hide-border", !payload);
        controls?.classList.toggle("tauri-hide-border", !payload);
    });

    window.neurokaraoke.listen("player", () => {
        console.log("player state change")
    });
    window.neurokaraoke.listen("player.shuffle", () => {
        console.log("player.shuffle state change")
    });
}