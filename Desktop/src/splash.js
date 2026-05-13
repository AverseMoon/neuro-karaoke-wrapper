import splash from "../assets/splash.html";
export default function () {
    let ftue = document.createElement("div");
    ftue.id = "tauri-ftue-container";
    ftue.innerHTML = splash;
    document.body.prepend(ftue);
}
