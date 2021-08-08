class Firefoxpwa < Formula
  desc "Tool to install, manage and use Progressive Web Apps in Mozilla Firefox"
  homepage "https://github.com/filips123/FirefoxPWA"
  url "https://github.com/filips123/FirefoxPWA/archive/refs/tags/v0.5.2.tar.gz"
  sha256 "ff62f0339883a2e806a5db1f912affd84fd6cd226dd8b158940fafba06562c75"
  license "MPL-2.0"
  head "https://github.com/filips123/FirefoxPWA.git"

  depends_on "rust" => :build

  def install
    cd "native"

    # Prepare the project to work with Homebrew
    ENV["FFPWA_SYSDATA"] = share
    system "bash", "./packages/brew/configure.sh", version, bin, libexec

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
    output = shell_output("#{bin}/firefoxpwa site launch 00000000000000000000000000 2>&1", 1)
    assert_includes output, "Runtime not installed"

    # NOTE: In 1.0.0 and future versions, the output will change to "Site does not exist"
    # assert_includes output, "Site does not exist"
  end
end
