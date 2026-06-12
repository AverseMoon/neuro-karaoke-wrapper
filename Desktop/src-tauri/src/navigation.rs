use tauri::{AppHandle, Manager, Url};

pub fn open_modal(app: &AppHandle, url: &Url, title: &str) -> tauri::Result<()> {
    app.get_webview_window("main").unwrap()
        .set_enabled(false)?;
    let modal = app.get_webview_window("modal").unwrap();
    modal.navigate(url.clone())?;
    modal.show()?;
    modal.set_focus()?;
    Ok(())
}

pub fn close_modal(app: &AppHandle) -> tauri::Result<()> {
    let modal = app.get_webview_window("modal").unwrap();
    modal.hide()?;
    modal.navigate("about:blank".parse().unwrap())?; // free up resources by loading blank page
    let main = app.get_webview_window("main").unwrap();
    main.set_enabled(true)?; // re-enable main window
    main.set_focus()?; // focus main window
    Ok(())
}

// every discord path you need to navigate to log in
const ALLOWED_DISCORD_PATHS: [&str; 2] = [
    "/api/oauth2/authorize",
    "/oauth2/authorize",
];

pub fn navigate_main(app: &AppHandle, url: &Url) -> bool {
    let host = match url.host_str() {
        Some(h) => h,
        None => return false,
    };

    if host == "neurokaraoke.com" || host.ends_with(".neurokaraoke.com") {
        return true;
    }

    if host == "discord.com" {
        open_modal(app, url, "Discord Login").unwrap();
        return false;
    }

    app.get_webview_window("main").unwrap()
        .navigate("https://neurokaraoke.com/".parse().unwrap()).unwrap();
    false
}

pub fn navigate_modal(app: &AppHandle, url: &Url) -> bool {
    if *url == "about:blank".parse().unwrap() {
        return true;
    }

    let host = match url.host_str() {
        Some(h) => h,
        None => return false,
    };

    if host == "neurokaraoke.com" || host.ends_with(".neurokaraoke.com") {
        app.get_webview_window("main").unwrap()
            .navigate(url.clone()).unwrap();
    }

    if host == "discord.com" {
        for path in ALLOWED_DISCORD_PATHS.iter() {
            if url.path() == *path {
                return true;
            }
        }
    }

    close_modal(app).unwrap();
    false
}