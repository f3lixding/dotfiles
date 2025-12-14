{ config, lib, pkgs, ... }:
let unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
  imports = [ ./spine.nix ];

  environment.systemPackages = with pkgs; [
    # DE 
    niri
    waybar
    wofi
    mako
    xwayland-satellite
    wpaperd
    bibata-cursors

    # chrome (because this is not a program for some reason)
    google-chrome

    # media
    unstable.spotify
    vesktop
    wechat
    plex-desktop

    # hardware related
    usbutils
  ];

  # desktop related
  programs.firefox.enable = true;
  environment.sessionVariables = { BROWSER = "firefox"; };

  # Set default browser
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
  };

  # DE
  programs.niri.enable = true;

  # steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
  ];
}

