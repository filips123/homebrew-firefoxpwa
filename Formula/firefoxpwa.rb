class Firefoxpwa < Formula
  desc "Tool to install, manage and use Progressive Web Apps in Mozilla Firefox"
  homepage "https://github.com/filips123/FirefoxPWA"
  url "https://github.com/filips123/FirefoxPWA/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "7785ae80a58c38c0ef88d3b6943f1202c8fbad69f848f57216e97e4dd75ba1c7"
  license "MPL-2.0"
  head "https://github.com/filips123/FirefoxPWA.git", branch: "main"

  bottle do
    root_url "https://github.com/filips123/homebrew-firefoxpwa/releases/download/firefoxpwa-1.1.1"
    sha256 cellar: :any_skip_relocation, catalina:     "78e3a8461c44207d8aa39bc5902cc88e065b81ef6ff4fa1dfcdd166054018472"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "4633f25146207d40ca7f47ad709622c998bd428e25dcf2be09e20b87afbbf58e"
  end

  depends_on "rust" => :build

  def install
    cd "native"

    # Prepare the project to work with Homebrew
    ENV["FFPWA_EXECUTABLES"] = opt_bin
    ENV["FFPWA_SYSDATA"] = opt_share
    system "bash", "./packages/brew/configure.sh", version, opt_bin, opt_libexec

    # Use vendored OpenSSL so Homebrew does not fail because of unwanted system libraries
    # NOTE: This will probably be switched to declaring OpenSSL as dependency in the future
    if OS.linux?
      inreplace "Cargo.toml",
                "[dependencies]",
                "[dependencies]\nopenssl = { version = \"0.10\", features = [\"vendored\"] }"
    end

    # Build and install the project
    system "cargo", "install", *std_cargo_args

    # Install all files
    libexec.install bin/"firefoxpwa-connector"
    share.install "manifests/brew.json" => "firefoxpwa.json"
    share.install "userchrome/"
    bash_completion.install "target/release/completions/firefoxpwa.bash" => "firefoxpwa"
    fish_completion.install "target/release/completions/firefoxpwa.fish"
    zsh_completion.install "target/release/completions/_firefoxpwa"
  end

  def caveats
    filename = "firefoxpwa.json"

    source = opt_share
    destination = "/Library/Application Support/Mozilla/NativeMessagingHosts"

    on_linux do
      destination = "/usr/lib/mozilla/native-messaging-hosts"
    end

    <<~EOS
      To use the browser extension, manually link the app manifest with:
        sudo mkdir -p #{destination}
        sudo ln -sf "#{source}/#{filename}" "#{destination}/#{filename}"
    EOS
  end

  test do
    # Test version so we know if Homebrew configure script correctly sets it
    assert_match "firefoxpwa #{version}", shell_output("#{bin}/firefoxpwa --version")

    # Test launching non-existing site which should fail
    output = shell_output("#{bin}/firefoxpwa site launch 00000000000000000000000000 2>&1", 1)
    assert_includes output, "Site does not exist"
  end
end
