{ config, lib, pkgs, ... }:
let
  spine-fhs = pkgs.buildFHSEnv {
    name = "spine";

    targetPkgs = pkgs:
      (with pkgs; [
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

    multiPkgs = pkgs:
      (with pkgs; [
        # 32-bit libraries that might be needed
        libGL
        libGLU
      ]);

    runScript = "bash -c 'cd ~/.cache/spine/Spine && ./Spine.sh'";

    profile = ''
      export LD_LIBRARY_PATH=/usr/lib:/usr/lib32
    '';
  };
in { environment.systemPackages = [ spine-fhs ]; }
