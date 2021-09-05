class Firefoxpwa < Formula
  desc "Tool to install, manage and use Progressive Web Apps in Mozilla Firefox"
  homepage "https://github.com/filips123/FirefoxPWA"
  url "https://github.com/filips123/FirefoxPWA/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "e3a18c742cc44d0ffde698753182733da75bfe9a2e331efddeb133c479108328"
  license "MPL-2.0"
  head "https://github.com/filips123/FirefoxPWA.git", branch: "main"

  bottle do
    root_url "https://github.com/filips123/homebrew-firefoxpwa/releases/download/firefoxpwa-1.0.0"
    rebuild 1
    sha256 cellar: :any_skip_relocation, catalina:     "12ccb692f17d407b2d31d895e10de3a53385997a436acfe0f291526d2eb1489f"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "a8d17ed867d280039d505de70d998b3b0b72e157ab44fbe2dec89edacfb66779"
  end

  depends_on "rust" => :build

  def install
    cd "native"

    # Prepare the project to work with Homebrew
    ENV["FFPWA_EXECUTABLES"] = bin
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
