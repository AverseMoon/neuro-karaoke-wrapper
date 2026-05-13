use tauri::{AppHandle, Manager, Url};

// every discord path you need to navigate to log in
const ALLOWED_DISCORD_PATHS: [&str; 2] = [
    "/api/oauth2/authorize",
    "/oauth2/authorize",
];

pub fn check_url(app: &AppHandle, url: &Url) -> bool {
    let host = match url.host_str() {
        Some(h) => h,
        None => return false,
    };

    // neurokaraoke
    if host == "neurokaraoke.com" || host.ends_with(".neurokaraoke.com") {
        return true;
    }

    // discord
    if host == "discord.com" {
        for path in ALLOWED_DISCORD_PATHS.iter() {
            if url.path() == *path {
                return true;
            }
        }
    }

    println!("URL failed test {}", url.as_str());
    app.get_webview_window("main").unwrap()
        .navigate("https://neurokaraoke.com/".parse().unwrap()).unwrap();
    false
}