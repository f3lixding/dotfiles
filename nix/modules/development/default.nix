{
  config,
  lib,
  pkgs,
  unstable,
  ...
}:
{
  imports = [
    ./zig.nix
    ./tuicr.nix
  ];

  environment.systemPackages = with pkgs; [
    unstable.ghostty
    tmux
    unstable.neovim
    unstable.claude-code
    unstable.codex
    unstable.pi-coding-agent
    unstable.pnpm
    unstable.pyright
    unstable.direnv
    unstable.clang-tools
    unstable.cmake
    git
    jujutsu
    wget
    difftastic
    fzf
    gcc
    gnumake
    ripgrep
    nixd
    nixfmt
    lua-language-server
    nitch
    yazi
    rustup
    tree-sitter
    unstable.opencode
  ];

  # shell
  programs.zsh = {
    enable = true;
    interactiveShellInit = ''
      nitch
    '';
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "sudo"
      ];
    };
  };
}
