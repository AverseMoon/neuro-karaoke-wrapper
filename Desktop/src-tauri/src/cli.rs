use clap::Parser;
use serde::Serialize;

#[derive(Parser, Debug)]
#[command(version, about)]
#[derive(Serialize)]
pub struct Cli {
    #[arg(long, help = "Enable OS window decorations")]
    pub enable_os_decorations: bool,
    #[arg(long, help = "Allow DevTools")]
    pub devtools: bool,
    #[arg(long, help = "Disable custom window buttons")]
    pub disable_custom_controls: bool,
}