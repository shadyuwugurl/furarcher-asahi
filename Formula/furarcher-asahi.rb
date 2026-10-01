class FurarcherAsahi < Formula
  desc "SFW furry/femboy Asahi Linux customizer + local Hermes AI companion"
  homepage "https://github.com/shadyuwugurl/furarcher-asahi"
  url "https://github.com/shadyuwugurl/furarcher-asahi/releases/download/v0.5.0/furarcher-asahi-0.5.0.tar.gz"
  sha256 "aff55371087083059b4199474714b649ef42fb1081d438d4070902f41ef0060b"
  license "GPL-3.0-only"

  depends_on "python@3.14"

  def install
    libexec.install Dir["*"] - ["Formula"]
    (bin/"furarcher").write_env_script libexec/"furarcher.sh", FURARCHER_ROOT: libexec
    bin.install_symlink libexec/"bin/furfetch"
    bin.install_symlink libexec/"bin/ricer"
    bin.install_symlink libexec/"furassistant/bin/furassistant"
  end

  def caveats
    <<~EOS
      The full `furarcher` installer targets Asahi Fedora Remix (M1 Air).
      The `furfetch` and `furassistant` CLIs also run on macOS
      (furassistant needs Ollama: `brew install ollama`).
      FurAssistant setup: `furassistant` data lives under ~/.local/share/furassistant;
      run the installer payload at #{opt_libexec}/furassistant/install-furassistant.sh
      for skills, personalities, timers, and the Hermes model.
    EOS
  end

  test do
    assert_match "furassistant", shell_output("#{bin}/furassistant")
    assert_match "furfetch", shell_output("#{bin}/furfetch")
  end
end
