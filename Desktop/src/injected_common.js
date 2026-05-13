import css from "../assets/injected.css";
import { getCurrentWindow } from "@tauri-apps/api/window";
// ran on all navigations
export async function pre() {
    const style = document.createElement("style");
    style.textContent = css;
    document.head.appendChild(style);
}
export async function post() {
    await getCurrentWindow().show();
}
