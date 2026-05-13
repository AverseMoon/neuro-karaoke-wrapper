use clap::{Parser, ValueEnum};
use serde::Serialize;

#[derive(Serialize, Clone, ValueEnum, Debug)]
pub enum Theme {
    #[serde(rename = "neuro")]
    Neuro,
    #[serde(rename = "twins")]
    Twins,
    #[serde(rename = "evil")]
    Evil,
}

#[derive(Parser, Serialize, Debug)]
#[command(version, about)]
pub struct Cli {
    #[arg(long, help = "Enable OS window decorations")]
    pub enable_os_decorations: bool,
    #[arg(long, help = "Allow DevTools")]
    pub devtools: bool,
    #[arg(long, help = "Disable custom window buttons")]
    pub disable_custom_controls: bool,
    #[arg(long, hide = true)]
    pub use_test_site: bool,
    #[arg(long, help = "Launch with a specific theme")]
    pub theme: Option<Theme>,
    #[arg(long, help = "Disable the URL checker")]
    pub disable_url_checking: bool,
    #[arg(long, help = "Disable single instance lock")]
    pub disable_single_instance_lock: bool,
    #[arg(long, help = "Reset all data (app and site)")]
    pub reset: bool,
}