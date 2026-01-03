{ config, lib, pkgs, unstable, ... }: {
  imports = [ ./zig.nix ];

  environment.systemPackages = with pkgs; [
    unstable.ghostty
    tmux
    neovim
    claude-code
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
      plugins = [ "git" "sudo" ];
    };
  };
}
