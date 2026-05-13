use std::process::Command;

fn main() {
    let status = Command::new("yarn")
        .arg("build")
        .current_dir("../")
        .status()
        .expect("failed to run yarn build");
    if !status.success() {
        panic!("yarn build failed");
    }


    tauri_build::build()
}
