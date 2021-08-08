class Firefoxpwa < Formula
  desc "Tool to install, manage and use Progressive Web Apps in Mozilla Firefox"
  homepage "https://github.com/filips123/FirefoxPWA"
  url "https://github.com/filips123/FirefoxPWA/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "47cb03a8f5773da235e360655a4ef93203d7d3ed760ebf6013692ec20239c2c1"
  license "MPL-2.0"
  head "https://github.com/filips123/FirefoxPWA.git"

  bottle do
    root_url "https://github.com/filips123/homebrew-firefoxpwa/releases/download/firefoxpwa-1.0.0"
    sha256 cellar: :any_skip_relocation, catalina:     "e22063c12afda6a335657f54121cb933350bb01e2f0fddeee7556b17756ecf96"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "1ae821ff2d81509ed1c87825d3adb7f983eeb75ad62442b4cccf6a9f11ba8e53"
  end

  depends_on "rust" => :build

  def install
    cd "native"

    # Prepare the project to work with Homebrew
    ENV["FFPWA_SYSDATA"] = share
    system "bash", "./packages/brew/configure.sh", version, bin, libexec

    # Use vendored OpenSSL so Homebrew does not fail because of unwanted system libraries
    # NOTE: This will be done in the configure script in future versions
    on_linux do
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

    source = share
    destination = "/Library/Application Support/Mozilla/NativeMessagingHosts"

    on_linux do
      destination = "/usr/lib/mozilla/native-messaging-hosts"
    end

    <<~EOS
      Before you can use the browser extension, you will need to manually link the app manifest
      This is needed because Homebrew formulae cannot access directories outside Homebrew directory

      To link the manifest, run the following commands after the formula is installed:
      $ sudo mkdir -p #{destination}
      $ sudo ln -sf "#{source}/#{filename}" "#{destination}/#{filename}"

      #{Tty.red}You will not be able to use the extension until you link the manifest!#{Tty.reset}
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
