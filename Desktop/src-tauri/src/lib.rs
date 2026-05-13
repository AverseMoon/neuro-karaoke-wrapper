use std::{fs, io};
use std::io::Write;
use std::sync::OnceLock;
use clap::Parser;
use tauri::{Manager, WebviewUrl, WebviewWindowBuilder};
use tauri_plugin_prevent_default::Flags;

mod cli;
mod sandbox;

static ARGS: OnceLock<cli::Cli> = OnceLock::new();

#[tauri::command]
fn greet(name: &str) -> String {
    println!("Hello, {}!", name);
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    ARGS.set(cli::Cli::parse()).unwrap();
    let args = ARGS.get().unwrap();

    if args.reset {
        let d = dirs::data_dir().and_then(|d| Some(d.join("com.soul.neurokaraoke")));
        if d.is_some() && fs::exists(d.as_ref().unwrap()).unwrap_or(false) {
            println!("About to delete: {}", d.as_ref().unwrap().as_os_str().to_str().unwrap());
            print!("Are you sure? (y/n): ");
            io::stdout().flush().unwrap();
            let mut input = String::new();
            io::stdin().read_line(&mut input).unwrap();

            if matches!(input.trim().to_lowercase().as_str(), "y" | "yes") {
                fs::remove_dir_all(d.as_ref().unwrap()).unwrap();
            }
        } else {
            eprintln!("Could not find data directory");
        }

        return;
    };

    let mut builder = tauri::Builder::default();

    if !args.disable_single_instance_lock {
        builder = builder.plugin(tauri_plugin_single_instance::init(|app, _, _| {
            app.get_webview_window("main")
                .unwrap()
                .set_focus()
                .unwrap();
        }));
    }

    builder = builder
        .plugin(tauri_plugin_prevent_default::Builder::new().with_flags(
            Flags::CONTEXT_MENU
        ).build())
        .invoke_handler(tauri::generate_handler![greet])
        .setup(|app| {
            let args = ARGS.get().unwrap();
            let handle = app.handle().clone();

            let builder = WebviewWindowBuilder::new(
                app,
                "main",
                WebviewUrl::External(
                    if args.use_test_site {"https://test.neurokaraoke.com/"} else {"https://neurokaraoke.com/"}
                    .parse().unwrap()
                )
            )

                // basic parameters
                .title("Neuro Karaoke")
                .visible(false)

                // sandboxing
                .on_navigation(move |url| sandbox::check_url(&handle, url))

                // order matters! `window.neurokaraokeapp` must be initialized before bundle.js runs!
                .initialization_script("window.neurokaraokeapp = {args:".to_owned()+&serde_json::to_string(args).unwrap()+"};")
                .initialization_script(include_str!("../../dist/bundle.js"))

                // program arg controlled parameters
                .devtools(args.devtools)
                .decorations(args.enable_os_decorations)
            ;


            let _webview = builder.build().expect("failed to build webview window");

            Ok(())
        });

    builder
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
