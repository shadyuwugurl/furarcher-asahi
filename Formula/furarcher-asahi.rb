class FurarcherAsahi < Formula
  desc "SFW furry/femboy Asahi Linux customizer + local Hermes AI companion"
  homepage "https://github.com/shadyuwugurl/furarcher-asahi"
  url "https://github.com/shadyuwugurl/furarcher-asahi/releases/download/v0.1.0/furarcher-asahi-0.1.0.tar.gz"
  sha256 "c8ed6f689af84bc114760dba6a376a3ba25044fec96005b7f4b203f47e39ecfd"
  license "GPL-3.0-only"

  depends_on "python@3.14"

  def install
    libexec.install Dir["*"] - ["Formula"]
    (bin/"furarcher").write_env_script libexec/"furarcher.sh", FURARCHER_ROOT: libexec
    bin.install_symlink libexec/"bin/furfetch"
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
