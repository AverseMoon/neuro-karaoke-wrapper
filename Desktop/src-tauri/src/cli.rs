use clap::Parser;
use serde::Serialize;

#[derive(Parser, Debug)]
#[command(version, about)]
#[derive(Serialize)]
pub struct Cli {
    #[arg(long, help = "Disable window decorations")]
    pub disable_decorations: bool,
    #[arg(long, help = "Allow DevTools")]
    pub devtools: bool,
}