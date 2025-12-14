{ config, lib, pkgs, ... }: {
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

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable =
    true; # Easiest to use and most distros use this by default.

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    22 # ssh
    57621 # for spotify to sync local tracks from fs with mobile devices on the same network
  ];
  networking.firewall.allowedUDPPorts =
    [ 5353 ]; # enable discovery of google cast devices

  # Allow qmk firmware to be recognized
  services.udev = {
    packages = with pkgs; [ qmk qmk-udev-rules qmk_hid via vial ];
  };

  # Audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # firmware update
  services.fwupd.enable = true;

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
}
