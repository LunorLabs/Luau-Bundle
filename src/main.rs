use std::fs;
use std::path::Path;
use chrono::Local;
use zip::write::FileOptions;
use zip::ZipWriter;
use std::io::Write;
use std::fs::File;
use walkdir::WalkDir;
use reqwest;
use serde_json::json;
use std::error::Error;
use tokio;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    // Get current date for version
    let now = Local::now();
    let version = format!("v{}", now.format("%Y.%m.%d"));

    // Read description from file
    println!("Reading description from description.md...");
    let description = match fs::read_to_string("description.md") {
        Ok(content) => content,
        Err(_) => format!(
            "Automated release {}\n\nChangelog:\n- Updated bundler package\n- Added automated installer",
            version
        ),
    };

    println!("Creating zip file...");
    
    // Create zip file
    let zip_path = Path::new("main.zip");
    let zip_file = File::create(&zip_path)?;
    let mut zip = ZipWriter::new(zip_file);
    let options = FileOptions::default()
        .compression_method(zip::CompressionMethod::Stored);

    // Add bundler folder to zip
    for entry in WalkDir::new("bundler") {
        let entry = entry?;
        let path = entry.path();
        
        if path.is_file() {
            let name = path.strip_prefix(Path::new("")).unwrap();
            println!("Adding to zip: {}", name.display());
            zip.start_file(name.to_str().unwrap(), options)?;
            let contents = fs::read(path)?;
            zip.write_all(&contents)?;
        }
    }

    // Add install.cmd to zip
    println!("Adding install.cmd to zip...");
    zip.start_file("install.cmd", options)?;
    let install_contents = fs::read("install.cmd")?;
    zip.write_all(&install_contents)?;

    zip.finish()?;
    println!("Zip file created successfully!");

    // Read the zip file and install.cmd
    let zip_contents = fs::read("main.zip")?;
    let install_cmd_contents = fs::read("install.cmd")?;

    // GitHub API configuration
    let github_token = std::env::var("GITHUB_TOKEN")
        .expect("GITHUB_TOKEN environment variable not set");
    
    let client = reqwest::Client::new();

    // Create release
    println!("Creating GitHub release...");
    let release_url = "https://api.github.com/repos/LunorLabs/Luau-Bundle/releases";
    let release_data = json!({
        "tag_name": version,
        "name": version,
        "body": description,
        "draft": false,
        "prerelease": false
    });

    let response = client.post(release_url)
        .header("Authorization", format!("token {}", github_token))
        .header("User-Agent", "Rust-Release-Bot")
        .json(&release_data)
        .send()
        .await?;

    let release_info: serde_json::Value = response.json().await?;
    let upload_url = release_info["upload_url"]
        .as_str()
        .unwrap()
        .replace("{?name,label}", "");

    // Upload the zip file
    println!("Uploading main.zip...");
    let upload_response = client.post(&format!("{}?name=main.zip", upload_url))
        .header("Authorization", format!("token {}", github_token))
        .header("Content-Type", "application/zip")
        .header("User-Agent", "Rust-Release-Bot")
        .body(zip_contents)
        .send()
        .await?;

    if !upload_response.status().is_success() {
        println!("Error uploading main.zip: {}", upload_response.text().await?);
        return Ok(());
    }

    // Upload install.cmd separately
    println!("Uploading install.cmd...");
    let install_response = client.post(&format!("{}?name=install.cmd", upload_url))
        .header("Authorization", format!("token {}", github_token))
        .header("Content-Type", "application/octet-stream")
        .header("User-Agent", "Rust-Release-Bot")
        .body(install_cmd_contents)
        .send()
        .await?;

    if install_response.status().is_success() {
        println!("Release {} created and files uploaded successfully!", version);
    } else {
        println!("Error uploading install.cmd: {}", install_response.text().await?);
    }

    Ok(())
}
