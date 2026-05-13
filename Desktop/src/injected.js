import injected_neurokaraoke from "./injected_neurokaraoke";
import injected_external from "./injected_external";
import { pre, post } from "./injected_common";
// primitive implementation of the soon-to-be added api for testing
// @ts-ignore
import ei from "./exampleImpl";
ei;
if (window.location.hostname == "neurokaraoke.com" ||
    window.location.hostname.endsWith(".neurokaraoke.com")) {
    if (window.neurokaraokeapp.args.theme)
        localStorage.setItem("theme", `"${window.neurokaraokeapp.args.theme}"`);
    document.addEventListener("DOMContentLoaded", async () => {
        await pre();
        await injected_neurokaraoke();
        await post();
    });
}
else
    document.addEventListener("DOMContentLoaded", async () => {
        await pre();
        await injected_external();
        await post();
    });
