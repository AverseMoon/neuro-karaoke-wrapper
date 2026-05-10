cask "neurokaraoke" do
  arch arm: "arm64", intel: "x64"

  version "1.5.2"
  sha256 arm:   "REPLACE_WITH_ARM64_SHA256",
         intel: "REPLACE_WITH_X64_SHA256"

  url "https://github.com/aferilvt/neuro-karaoke-wrapper/releases/download/v#{version}/Neuro%20Karaoke%20Player-#{version}-#{arch}.dmg",
      verified: "github.com/aferilvt/neuro-karaoke-wrapper/"
  name "Neuro Karaoke Player"
  desc "Karaoke player for Neuro-sama AI covers"
  homepage "https://neurokaraoke.com"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  app "Neuro Karaoke Player.app"

  zap trash: [
    "~/Library/Application Support/Neuro Karaoke Player",
    "~/Library/Preferences/com.neurokaraoke.app.plist",
    "~/Library/Logs/Neuro Karaoke Player",
    "~/Library/Caches/com.neurokaraoke.app",
    "~/Library/Saved Application State/com.neurokaraoke.app.savedState",
  ]
end
