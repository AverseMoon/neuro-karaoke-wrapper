use std::sync::OnceLock;
use clap::Parser;
use tauri::{WebviewUrl, WebviewWindowBuilder};
mod cli;

static ARGS: OnceLock<cli::Cli> = OnceLock::new();

#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    ARGS.set(cli::Cli::parse()).unwrap();
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![greet])
        .setup(|app| {
            let args = ARGS.get().unwrap();

            let builder = WebviewWindowBuilder::new(
                app,
                "main",
                WebviewUrl::External("https://neurokaraoke.com/".parse().unwrap())
            )

                // basic parameters
                .title("Neuro Karaoke")


                // order matters! `window.neurokaraokeapp` must be initialized before bundle.js runs!
                .initialization_script("window.neurokaraokeapp = {args:".to_owned()+&serde_json::to_string(args).unwrap()+"};")
                .initialization_script(include_str!("../../dist/bundle.js"))

                // program arg controlled parameters
                .devtools(args.devtools)
                .decorations(args.enable_os_decorations)
            ;


            let _webview = builder.build().expect("failed to build webview window");

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
