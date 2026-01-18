{
  config,
  lib,
  pkgs,
  ...
}:

let
  zig-latest = pkgs.stdenv.mkDerivation {
    pname = "zig";
    version = "0.15.2";

    src = builtins.fetchTarball {
      url = "https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz";
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
    version = "0.15.1";

    src = builtins.fetchTarball {
      url = "https://github.com/zigtools/zls/releases/download/0.15.1/zls-x86_64-linux.tar.xz";
      sha256 = "1w00vdf0yb3q7avpdzgwifjvld4bx4snfbj27y02ha9br5lw6ibd";
    };

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/bin
      # The tarball contains just the 'zls' binary
      install -m755 zls $out/bin/zls
    '';
  };
in
{
  environment.systemPackages = [
    zig-latest
    zls-latest
  ];
}
