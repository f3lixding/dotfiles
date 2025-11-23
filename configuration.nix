# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let 
  zig-0-15-1 = pkgs.stdenv.mkDerivation {
    pname = "zig";
    version = "0.15.1";

    src = pkgs.fetchurl {
      url = "https://ziglang.org/download/0.15.1/zig-x86_64-linux-0.15.1.tar.xz";
      sha256 = "01gyz8xjjj0qs0rxp0q34psrw67lqqh4apnd3sjlr8gfxnk5s766";
    };
    
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      cp -r lib $out/
      cp -r doc $out/
      cp zig $out/bin/
    '';
  };
  
  zls-0-15-0 = pkgs.stdenv.mkDerivation {
    pname = "zls";
    version = "0.15.0";

    src = pkgs.fetchurl {
      url = "https://builds.zigtools.org/zls-x86_64-linux-0.15.0.tar.xz";
      sha256 = "1pih3bqb89mfbmf6h0vb243z8l83j2l7vz7k0wps1lipsqzzx2sh";
    };

    sourceRoot = ".";

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      # The tarball contains just the 'zls' binary
      install -m755 zls $out/bin/zls
    '';
  };

  spine-fhs = pkgs.buildFHSEnv {
    name = "spine";
    
    targetPkgs = pkgs: (with pkgs; [
      # Java
      jdk17
      
      # X11 libraries - these provide the .so files
      xorg.libX11
      xorg.libXext
      xorg.libXi
      xorg.libXtst
      xorg.libXrender
      xorg.libXrandr
      xorg.libXxf86vm
      xorg.libXcursor
      xorg.libXinerama
      xorg.xdpyinfo
      xorg.xrandr
      
      # OpenGL/Mesa
      libGL
      libGLU
      mesa
      
      # Audio
      alsa-lib
      libpulseaudio
      
      # Other deps
      freetype
      fontconfig
      zlib
      glib
      gtk3
      cairo
      pango
      atk
      gdk-pixbuf
      
      # C++ stdlib
      stdenv.cc.cc.lib
    ]);
    
    multiPkgs = pkgs: (with pkgs; [
      # 32-bit libraries that might be needed
      libGL
      libGLU
    ]);
    
    runScript = "bash -c 'cd ~/.cache/spine/Spine && ./Spine.sh'";
    
    profile = ''
      export LD_LIBRARY_PATH=/usr/lib:/usr/lib32
    '';
  };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # compatibility related
  nixpkgs.config.allowUnfree = true;

  # firmware update
  services.fwupd.enable = true;

  # Experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Power management
  powerManagement.enable = true;
  powerManagement.powerDownCommands = ''
    ${pkgs.kmod}/bin/modprobe -r mt7925e
  '';
  powerManagement.powerUpCommands = ''
    ${pkgs.kmod}/bin/modprobe mt7925e
  '';
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="pcieport", ATTR{power/wakeup}="disabled"
  '';

  # Allow qmk firmware to be recognized
  services.udev = {
    packages = with pkgs; [
      qmk
      qmk-udev-rules
      qmk_hid
      via
      vial
    ]; 
  }; 

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 
    22     # ssh
    57621  # for spotify to sync local tracks from fs with mobile devices on the same network 
  ]; 
  networking.firewall.allowedUDPPorts = [ 5353 ]; # enable discovery of google cast devices
  
  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.felix = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
   };

  environment.systemPackages = with pkgs; [
    # DE related stuff
    niri
    waybar
    wofi
    mako
    xwayland-satellite
    wpaperd
    bibata-cursors
    
    # development tools
    ghostty
    tmux
    neovim
    git
    jujutsu
    wget
    fzf
    gcc
    gnumake
    ripgrep
    nixd
    lua-language-server

    # chrome (because this is not a program for some reason)
    google-chrome

    # media
    spotify
    vesktop
    wechat
    plex-desktop

    # hardware related
    usbutils

    # rust toolchain
    rustup
  ] ++ [
    # zig toolchains
    zig-0-15-1
    zls-0-15-0

    # spine wrapper
    spine-fhs
  ];

  # shell
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "sudo" ];
    };
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
    };
  };
  
  # login screen
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd niri-session";
      };
    };
  };

  # desktop related
  programs.firefox.enable = true;
  environment.sessionVariables = {
    BROWSER = "firefox";
  };

  # Set default browser
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
  };
  programs.niri.enable = true;
  
  # steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools
    ];
    extraPackages32 = with pkgs; [
      pkgsi686Linux.amdvlk
      pkgsi686Linux.vulkan-loader
    ];
  };

  # fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
  ];


  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}

