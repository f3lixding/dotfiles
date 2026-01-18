{ config, lib, pkgs, ... }:

let
  zig-latest = pkgs.stdenv.mkDerivation {
    pname = "zig";
    version = "0.15.2";

    src = builtins.fetchTarball {
      url =
        "https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz";
      sha256 = "0skmy2qjg2z4bsxnkdzqp1hjzwwgnvqhw4qjfnsdpv6qm23p4wm0";
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

    src = builtins.fetchTarball {
      url = "https://builds.zigtools.org/zls-x86_64-linux-0.15.0.tar.xz";
      sha256 = "1jdl9sa8f1nxy6j7jydr1g0ixw4rf6b9myalnljhy9xwwi1d3lhs";
    };

    sourceRoot = ".";

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      # The tarball contains just the 'zls' binary
      install -m755 $src/zls $out/bin/zls
    '';
  };
in { environment.systemPackages = [ zig-latest zls-latest ]; }
