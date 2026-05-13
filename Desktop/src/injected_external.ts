// ran on sites other than neurokaraoke.com
export default async function() {
    const backBtn = document.createElement("button");
    backBtn.id = "tauri-back-button";
    backBtn.onclick = () => { window.location.href = "https://neurokaraoke.com/"; }
    backBtn.innerHTML = "&larr;"
    document.body.prepend(backBtn);
}