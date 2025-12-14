{ config, lib, pkgs, ... }:

let
  zig-latest = pkgs.stdenv.mkDerivation {
    pname = "zig";
    version = "0.15.2";

    src = pkgs.fetchurl {
      url =
        "https://ziglang.org/builds/zig-x86_64-linux-0.16.0-dev.1484+d0ba6642b.tar.xz";
      sha256 = "0yrf9avjmj7lw9dwiqgczgz1s4r0cwx2ipdip6ls8kkfvqn5i41z";
    };

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      cp -r lib $out/
      cp -r doc $out/
      cp zig $out/bin/
    '';
  };

  zls-latest = pkgs.stdenv.mkDerivation {
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
in { environment.systemPackages = [ zig-latest zls-latest ]; }
