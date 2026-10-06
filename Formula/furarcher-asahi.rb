class FurarcherAsahi < Formula
  desc "SFW furry/femboy Asahi Linux customizer + local Hermes AI companion"
  homepage "https://github.com/shadyuwugurl/furarcher-asahi"
  url "https://github.com/shadyuwugurl/furarcher-asahi/releases/download/v0.6.9/furarcher-asahi-0.6.9.tar.gz"
  sha256 "719dab794de5483c51745968f5030e53d86073e7903262d5f69680ae92d760ec"
  license "GPL-3.0-only"

  depends_on "python@3.14"

  def install
    libexec.install Dir["*"] - ["Formula"]
    # wrappers (not symlinks): $0-based payload lookup breaks under Cellar,
    # so every entry point gets FURARCHER_ROOT=libexec explicitly.
    (bin/"furarcher").write_env_script libexec/"furarcher.sh", FURARCHER_ROOT: libexec
    (bin/"furfetch").write_env_script libexec/"bin/furfetch", FURARCHER_ROOT: libexec
    (bin/"ricer").write_env_script libexec/"bin/ricer", FURARCHER_ROOT: libexec
    (bin/"furassistant").write_env_script libexec/"furassistant/bin/furassistant", FURARCHER_ROOT: libexec
    (bin/"macrice").write_env_script libexec/"macos/macrice.sh", FURARCHER_ROOT: libexec
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
